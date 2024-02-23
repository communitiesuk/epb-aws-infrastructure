function handler(event) {

    var request = event.request

    if (request.uri.includes("lang=cy")){
        request.uri = '/cy/service-unavailable.html'
    } else {
        request.uri = '/en/service-unavailable.html'
    }

    return request;
}