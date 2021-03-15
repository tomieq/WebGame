var webSocket = 0;
var websocketHandler;

$( document ).ready(function() {
    webSocket = new WebSocket("ws://localhost:5920/websocket");
    websocketHandler = new WebSocketHandler();
    
    webSocket.onopen = function (event) {
        console.log("[webSocket] Connection established");
        webSocket.send("connected");
    };
    webSocket.onmessage = function (event) {
        websocketHandler.incoming(event.data);
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
        dto["dto"] = data;
        webSocket.send(JSON.stringify(dto));
    } else {
        console.log("[websocker] sending problem. webSocket.readyState="+webSocket.readyState);
    }
}

class WebSocketHandler {
    construct() {
    }
    
    incoming(text) {
        var json = JSON.parse(text);
        if(json["command"] == undefined) {
            console.log("[webSocket] [message error] " + text);
            return;
        }
        switch (json["command"]) {
            case "startVehicle":
                var dto = json["dto"];
                var points = [];
                if( dto["points"] != undefined && dto["speed"] != undefined && dto["id"] != undefined && dto["type"] != undefined ) {
                    for (var i=0; i < dto["points"].length; i++) {
                        var point = dto["points"][i];
                        points.push(new MapPoint(point["x"], point["y"]));
                    }
                    gameTraffic.addObject(dto["id"], dto["type"], points, dto["speed"]);
                }
                break;
            default:
                console.log("[webSocket] [unknown command] " + json["command"]);
                break;
        }
    }
}
