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
            gameDisconnected()
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
                  console.log( "Loaded map tiles" );
                });
                break;
            case "reloadAddonsMap":
                $.getScript( "js/loadAddonsMap.js", function( data, textStatus, jqxhr ) {
                  console.log( "Loaded addon map tiles" );
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
                    highlightTiles(points, payload["color"]);
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
                var payload = json["payload"];
                var text = payload["text"];
                var secondsLeft = payload["secondsLeft"];
                updateGameDate(text, secondsLeft);
                break;
            case "notification":
                var payload = json["payload"];
                var text = payload["text"];
                var icon = payload["icon"]
                if (icon.length > 0 ) {
                    text = "<div class='notification-icon' style='"+iconBorder(payload["level"])+"'><img src='images/"+icon+".png' /></div>" + text;
                }
                new Noty({
                    text: text,
                    theme: 'bootstrap-v4',
                    layout: 'topRight',
                    type: payload["level"],
                    timeout: payload["duration"] * 1000
                }).show();
                break;
            case "runScript":
                var url = json["payload"];
                runScripts(0, [url])
            default:
                console.log("[webSocket] [unknown command] " + json["command"]);
                break;
        }
    }
}


function iconBorder(notificationLevel) {
    switch (notificationLevel) {
        case "warning":
            return "border: 1px solid #8A6D3A;";
        case "info":
            return "border: 1px solid#6797AE;";
        case "error":
            return "border: 1px solid#AA4442;";
        case "success":
            return "border: 1px solid#6F9D6D;";
    }
}
