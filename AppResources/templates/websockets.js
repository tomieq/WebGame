var webSocket = 0;

$( document ).ready(function() {
    webSocket = new WebSocket("ws://localhost:5920/websocket");
    
    webSocket.onopen = function (event) {
        console.log("[webSocket] Connection established");
        webSocket.send("connected");
    };
    webSocket.onmessage = function (event) {
        console.log("[webSocket] [message] " + event.data);
    }
    webSocket.onclose = function(event) {
        if (event.wasClean) {
            console.log("[webSocket] [close] Connection closed cleanly, code="+event.code + " reason=" + event.reason);
        } else {
        // e.g. server process killed or network down
        // event.code is usually 1006 in this case
            alert('[webSocket] [close] Connection died');
        }
    };

    webSocket.onerror = function(error) {
        console.log("'[webSocket] [error]" + error.message);
    };
});

function syncData(command, data) {
    if (webSocket.readyState == 1) {
        var dto = {};
        dto["command"] = command;
        dto["data"] = data;
        webSocket.send(JSON.stringify(dto));
    } else {
        console.log("[websocker] sending problem. webSocket.readyState="+webSocket.readyState);
    }
}
