function handler(event) {
    var host = event.request.headers.host.value;

    var uri = event.request.uri;

    var newUrl;

    if (host === "${OLD_GET_HOST}") {
        newUrl = `https://${NEW_GET_HOST}/`;
    } else if (uri === "/service-performance" ) {
        newUrl = `https://${NEW_FIND_HOST}$${uri}`;
    } else if (uri.match(/^\/energy-certificate\/\d{4}-\d{4}-\d{4}-\d{4}/)) {
        newUrl = `https://${NEW_FIND_HOST}$${uri}`;
    } else {
        newUrl = `https://${NEW_FIND_HOST}/`;
    }

    var response = {
        statusCode: 301,
        statusDescription: "Moved Permanently",
        headers: {
            "location": {
                value: newUrl,
            },
        },
    };

    return response;
}