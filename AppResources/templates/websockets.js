var webSocket = 0;
var websocketHandler;
var playerSessionID = "{playerSessionID}";

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
            alert('[webSocket] [close] Connection died ' + event.code);
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
        console.log("Incoming websocket data: " + text);
        var json = JSON.parse(text);
        if(json["command"] == undefined) {
            console.log("[webSocket] [message error] " + text);
            return;
        }
        switch (json["command"]) {
            case "startVehicle":
                var payload = json["payload"];
                var points = [];
                if( payload["travelPoints"] != undefined && payload["speed"] != undefined && payload["id"] != undefined && payload["vehicleType"] != undefined ) {
                    for (var i=0; i < payload["travelPoints"].length; i++) {
                        var point = payload["travelPoints"][i];
                        points.push(new MapPoint(point["x"], point["y"]));
                    }
                    gameTraffic.addObject(payload["id"], payload["vehicleType"], points, payload["speed"]);
                }
                break;
            case "reloadMap":
                $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
                  console.log( "Load map performed." );
                });
                break;
            case "highlightArea":
                var payload = json["payload"];
                var points = [];
                if(payload["points"] != undefined && payload["color"] != undefined) {
                    for (var i=0; i < payload["points"].length; i++) {
                        var point = payload["points"][i];
                        points.push(new MapPoint(point["x"], point["y"]));
                    }
                    gameInteractionMap.drawTiles(points, payload["color"]);
                }
                break;
            case "openWindow":
                var payload = json["payload"];
                var x = -1;
                var y = -1;
                if(payload["address"] != undefined ) {
                    x = payload["address"]["x"];
                    y = payload["address"]["y"];
                }
                openWindow(payload["title"], payload["initUrl"], payload["width"], payload["height"], x, y);
                break;
            case "updateWallet":
                updateWallet(json["payload"]);
                break;
            case "updateGameDate":
                updateGameDate(json["payload"]);
                break;
            case "notification":
                var payload = json["payload"];
                new Noty({
                    text: payload["text"],
                    theme: 'bootstrap-v4',
                    layout: 'topRight',
                    type: payload["level"],
                    timeout: payload["duration"] * 1000
                }).show();
                break;
            default:
                console.log("[webSocket] [unknown command] " + json["command"]);
                break;
        }
    }
}
