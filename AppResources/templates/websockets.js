var webSocket = 0;
var websocketHandler;

$( document ).ready(function() {
    webSocket = new WebSocket("{url}");
    websocketHandler = new WebSocketHandler();
    
    webSocket.onopen = function (event) {
        console.log("[webSocket] Connection established");
        syncData("playerSessionID", "{playerSessionID}");
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
        dto["payload"] = data;
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
                var data = json["payload"];
                var points = [];
                if( data["travelPoints"] != undefined && data["speed"] != undefined && data["id"] != undefined && data["vehicleType"] != undefined ) {
                    for (var i=0; i < data["travelPoints"].length; i++) {
                        var point = data["travelPoints"][i];
                        points.push(new MapPoint(point["x"], point["y"]));
                    }
                    gameTraffic.addObject(data["id"], data["vehicleType"], points, data["speed"]);
                }
                break;
            case "reloadMap":
                $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
                  console.log( "Load map performed." );
                });
            default:
                console.log("[webSocket] [unknown command] " + json["command"]);
                break;
        }
    }
}
