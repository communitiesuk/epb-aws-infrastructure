function handler(event) {
    var authHeaders = event.request.headers.authorization;

    // If an Authorization header is supplied and contains has a Bearer token
    // request on through to CF/the origin without any modification.
    if (authHeaders && authHeaders.value.match(/^Bearer\s[a-zA-Z0-9]{64}$/)) {
        return event.request;
    }

    // Deny the request if the header is missing or incorrect
    return {
        statusCode: 403,
        statusDescription: 'Forbidden',
        body: {
            encoding: 'text',
            data: 'Access denied. Bad authentication header.'
        }
    };
}