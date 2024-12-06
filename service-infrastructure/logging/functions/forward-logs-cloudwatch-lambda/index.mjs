'use strict';

import { CloudWatchLogsClient, DescribeLogGroupsCommand, CreateLogGroupCommand, DescribeLogStreamsCommand, CreateLogStreamCommand, PutLogEventsCommand } from "@aws-sdk/client-cloudwatch-logs";
import { S3Client, GetObjectCommand } from '@aws-sdk/client-s3'
const s3Client = new S3Client({
    apiVersion: '2006-03-01',
})
const cloudWatchLogsClient = new CloudWatchLogsClient({
    apiVersion: '2014-03-28'
});
import zlib from 'zlib';
import readline from 'readline';
import stream from 'stream';
import { Buffer } from 'node:buffer';

let logGroupName = process.env.logGroupName// Name of the log group goes here;
let logStreamName // Name of the log stream goes here;

export const handler = async (event, context, callback) => {
    // We are attaching this lambda as event notification - So the event will contains details about the object
    // to see the sample refer to this URL - https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html

    logStreamName = context.logStreamName
    console.log('S3 object is:', event.Records[0].s3);
    const bucket = event.Records[0].s3.bucket.name;
    console.log('Name of S3 bucket is:', bucket);
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));
    console.log('Name of key is:', key)


    // Retrieve S3 Object based on the bucket and key name in the event parameter
    try {
        const response = await s3Client.send(new GetObjectCommand({
            Key: key,
            Bucket: bucket,
        }))

        const stream = await response.Body

        const buffered_data = Buffer.concat(await stream.toArray())

        zlib.gunzip(buffered_data, async function (error, buffer) {
            if (error) {
                console.log('Error uncompressing data', error);
                return;
            }

            const logData = buffer.toString('ascii');
            await manageLogGroups(logData);

        });
        callback(null, response.ContentType);
    } catch (error) {
        console.log(error);
        const message = `Error getting object ${key} from bucket ${bucket}. Make sure they exist and your bucket is in the same region as this function.`;
        console.log(message);
        callback(message);
    }

    // Manage the log group
    async function manageLogGroups(logData) {
        const describeLogGroupParams = {
            logGroupNamePrefix: logGroupName
        };

        //check if the log group already exists
        try {
            const data = await cloudWatchLogsClient.send(new DescribeLogGroupsCommand(describeLogGroupParams))

            if (!data.logGroups[0]) {
                console.log('Need to  create log group:', data);
                //create log group
                await createLogGroup(logData);
            } else {
                console.log('Success while describing log group:', data);
                await manageLogStreams(logData);
            }
        } catch (error) {
            console.log('Error while describing log group:', error);
            await createLogGroup(logData);
        }
    }

    // Create log group
    async function createLogGroup(logData) {
        const logGroupParams = {
            logGroupName: logGroupName
        };

        try {
            await cloudWatchLogsClient.send(new CreateLogGroupCommand(logGroupParams))
            console.log('Success in creating log group: ', logGroupName);
            await manageLogStreams(logData);
        } catch (error) {
            console.log('error while creating log group: ', error, error.stack);
        }
    }


    // Manage the log stream and get the sequenceToken - The sequence token is the order of the logs being added to the stream
    async function manageLogStreams(logData) {
        const describeLogStreamsParams = {
            logGroupName: logGroupName,
            logStreamNamePrefix: logStreamName
        };

        // check if the log stream already exists and get the sequenceToken
        // Logs within the same period might be put into the same log stream, it is important to check fi the log stream exists
        try {
            const data = await cloudWatchLogsClient.send(new DescribeLogStreamsCommand(describeLogStreamsParams))
            if (!data.logStreams[0]) {
                console.log('Need to  create log stream:', data);
                await createLogStream(logData);
            } else {
                console.log('Log Stream already defined:', logStreamName);
                putLogEvents(data.logStreams[0].uploadSequenceToken, logData);
            }
        } catch (error) {
            console.log('Error during describe log streams:', error);
            await createLogStream(logData);
        }
    }

    // Create Log Stream
    async function createLogStream(logData) {
        const logStreamParams = {
            logGroupName: logGroupName,
            logStreamName: logStreamName
        };

        try {
            await cloudWatchLogsClient.send( new CreateLogStreamCommand(logStreamParams))
            console.log('Success in creating log stream: ', logStreamName);
            putLogEvents(null, logData);
        } catch (error) {
            console.log('error while creating log stream: ', error, error.stack);
        }
    }

    function putLogEvents(sequenceToken, logData) {
        //From http://docs.aws.amazon.com/AmazonCloudWatchLogs/latest/APIReference/API_PutLogEvents.html
        const MAX_BATCH_SIZE = 1048576; // maximum size in bytes of Log Events (with overhead) per invocation of PutLogEvents
        const MAX_BATCH_COUNT = 10000; // maximum number of Log Events per invocation of PutLogEvents
        const LOG_EVENT_OVERHEAD = 26; // bytes of overhead per Log Event

        // holds a list of batches
        const batches = [];

        // holds the list of events in current batch
        let batch = [];

        // size of events in the current batch
        let batch_size = 0;

        const bufferStream = new stream.PassThrough();
        bufferStream.end(logData);

        // Read reach line of logs and add it into batch
        const rl = readline.createInterface({
            input: bufferStream
        });

        let line_count = 0;

        rl.on('line', (line) => {
            ++line_count;
            if (line[0] != "#") {
                let timeValue
                // need to add logic to deal with different types of logs
                const firstChar = line.charAt(0)
                if (firstChar >= '0' && firstChar <= '9') {
                    const d = line.split("\t")[0];
                    const t = line.split("\t")[1];
                    timeValue = Date.parse(d+'T'+t);
                    // it is a number
                } else {
                    const ts = line.split(" ")[1];
                    timeValue = Date.parse(ts);
                }

                const event_size = line.length + LOG_EVENT_OVERHEAD;

                batch_size += event_size;

                if (batch_size >= MAX_BATCH_SIZE ||
                    batch.length >= MAX_BATCH_COUNT) {
                    // start a new batch
                    batches.push(batch);
                    batch = [];
                    batch_size = event_size;
                }

                batch.push({
                    message: line,
                    timestamp: timeValue
                });
            }
        //

        });

        rl.on('close', () => {
            // add the final batch
            batches.push(batch);
            sendBatches(sequenceToken, batches);
        });
    }

    function sendBatches(sequenceToken, batches) {
        let count = 0;
        let batch_count = 0;

        async function sendNextBatch(err, nextSequenceToken) {
            if (err) {
                console.log('Error sending batch: ', err, err.stack);
                return;
            } else {
                const nextBatch = batches.shift();
                if (nextBatch) {
                    // send this batch
                    ++batch_count;
                    count += nextBatch.length;
                    await sendBatch(nextSequenceToken, nextBatch, sendNextBatch);
                } else {
                    // no more batches: we are done
                    const msg = `Successfully put ${count} events in ${batch_count} batches`;
                    console.log(msg);
                    callback(null, msg);
                }
            }
        }

        sendNextBatch(null, sequenceToken);
    }

    async function sendBatch(sequenceToken, batch, doNext) {
        const putLogEventParams = {
            logEvents: batch,
            logGroupName: logGroupName,
            logStreamName: logStreamName
        };
        if (sequenceToken) {
            putLogEventParams['sequenceToken'] = sequenceToken;
        }

        // sort the events in ascending order by timestamp as required by PutLogEvents
        putLogEventParams.logEvents.sort(function (a, b) {
            if (a.timestamp > b.timestamp) {
                return 1;
            }
            if (a.timestamp < b.timestamp) {
                return -1;
            }
            return 0;
        });

        try {
            const data = await cloudWatchLogsClient.send(new PutLogEventsCommand(putLogEventParams))
            console.log(`Success in putting ${putLogEventParams.logEvents.length} events`);
            doNext(null, data.nextSequenceToken);
        } catch (error) {
            console.log('Error during put log events: ', error, error.stack);
            doNext(error, null);
        }
    }
};