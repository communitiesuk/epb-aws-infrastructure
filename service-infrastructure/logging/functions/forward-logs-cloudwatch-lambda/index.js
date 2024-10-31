'use strict';

const aws = require('aws-sdk');
const zlib = require('zlib');
const s3 = new aws.S3({ apiVersion: '2006-03-01' });
const cloudWatchLogs = new aws.CloudWatchLogs({
    apiVersion: '2014-03-28'
});

const readline = require('readline');
const stream = require('stream');

let logGroupName = process.env.logGroupName// Name of the log group goes here;
let logStreamName // Name of the log stream goes here;

exports.handler = (event, context, callback) => {
    // We are attaching this lambda as event notification - So the event will contains details about the object
    // to see the sample refer to this URL - https://docs.aws.amazon.com/lambda/latest/dg/with-s3.html

    logStreamName = context.logStreamName
    console.log('S3 object is:', event.Records[0].s3);
    const bucket = event.Records[0].s3.bucket.name;
    console.log('Name of S3 bucket is:', bucket);
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, ' '));


    // Retrieve S3 Object based on the bucket and key name in the event parameter
    const params = {
        Bucket: bucket,
        Key: key,
    };
    s3.getObject(params, (err, data) => {
        if (err) {
            console.log(err);
            const message = `Error getting object ${key} from bucket ${bucket}. Make sure they exist and your bucket is in the same region as this function.`;
            console.log(message);
            callback(message);
        } else {
            //uncompressing the S3 data - most logs in S3 is in GZ format
            zlib.gunzip(data.Body, function (error, buffer) {
                if (error) {
                    console.log('Error uncompressing data', error);
                    return;
                }

                const logData = buffer.toString('ascii');
                manageLogGroups(logData);

            });
            callback(null, data.ContentType);
        }
    });

    // Manage the log group
    function manageLogGroups(logData) {

        const describeLogGroupParams = {
            logGroupNamePrefix: logGroupName
        };

        //check if the log group already exists
        cloudWatchLogs.describeLogGroups(describeLogGroupParams, function (err, data) {
            if (err) {
                console.log('Error while describing log group:', err);
                createLogGroup(logData);
            } else {
                if (!data.logGroups[0]) {
                    console.log('Need to  create log group:', data);
                    //create log group
                    createLogGroup(logData);
                } else {
                    console.log('Success while describing log group:', data);
                    manageLogStreams(logData);
                }
            }
        });
    }

    // Create log group
    function createLogGroup(logData) {
        const logGroupParams = {
            logGroupName: logGroupName
        };
        cloudWatchLogs.createLogGroup(logGroupParams, function (err, data) {
            if (err) {
                console.log('error while creating log group: ', err, err.stack);
                return;
            } else {
                console.log('Success in creating log group: ', logGroupName);
                manageLogStreams(logData);
            }
        });
    }


    // Manage the log stream and get the sequenceToken - The sequence token is the order of the logs being added to the stream
    function manageLogStreams(logData) {
        const describeLogStreamsParams = {
            logGroupName: logGroupName,
            logStreamNamePrefix: logStreamName
        };

        // check if the log stream already exists and get the sequenceToken
        // Logs within the same period might be put into the same log stream, it is important to check fi the log stream exists
        cloudWatchLogs.describeLogStreams(describeLogStreamsParams, function (err, data) {
            if (err) {
                console.log('Error during describe log streams:', err);
                createLogStream(logData);
            } else {
                if (!data.logStreams[0]) {
                    console.log('Need to  create log stream:', data);
                    createLogStream(logData);
                } else {
                    console.log('Log Stream already defined:', logStreamName);
                    putLogEvents(data.logStreams[0].uploadSequenceToken, logData);
                }
            }
        });
    }

    // Create Log Stream
    function createLogStream(logData) {
        const logStreamParams = {
            logGroupName: logGroupName,
            logStreamName: logStreamName
        };

        cloudWatchLogs.createLogStream(logStreamParams, function (err, data) {
            if (err) {
                console.log('error while creating log stream: ', err, err.stack);
                return;
            } else {
                console.log('Success in creating log stream: ', logStreamName);
                putLogEvents(null, logData);
            }
        });
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

        function sendNextBatch(err, nextSequenceToken) {
            if (err) {
                console.log('Error sending batch: ', err, err.stack);
                return;
            } else {
                const nextBatch = batches.shift();
                if (nextBatch) {
                    // send this batch
                    ++batch_count;
                    count += nextBatch.length;
                    sendBatch(nextSequenceToken, nextBatch, sendNextBatch);
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

    function sendBatch(sequenceToken, batch, doNext) {
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

        cloudWatchLogs.putLogEvents(putLogEventParams, function (err, data) {
            if (err) {
                console.log('Error during put log events: ', err, err.stack);
                doNext(err, null);
            } else {
                console.log(`Success in putting ${putLogEventParams.logEvents.length} events`);
                doNext(null, data.nextSequenceToken);
            }
        });
    }

};