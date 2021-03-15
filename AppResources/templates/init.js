var calculator = new GameCalculator({mapWidth}, {mapHeight}, {mapScale});
var gameStreetMap;
var gameInteractionMap;
var gameTraffic;
var gameBuildingsMap;

$( document ).ready(function() {
    var canvasStreets  = $('#canvasStreets');
    gameStreetMap = new GameMap(canvasStreets, calculator);
    gameStreetMap.drawGround();
    gameStreetMap.drawCoordinates();
    
    var canvasInteraction = $("#canvasInteraction");
    gameInteractionMap = new GameMap(canvasInteraction, calculator);
    

    var canvasBuildings  = $('#canvasBuildings');
    gameBuildingsMap = new GameMap(canvasBuildings, calculator);

    var canvasTraffic  = $('#canvasTraffic');
    gameTraffic = new GameTraffic(canvasTraffic, calculator);

    canvasBuildings.click(function() {
      var points = [new MapPoint(0, 1), new MapPoint(2, 1), new MapPoint(2, 4), new MapPoint(4, 4), new MapPoint(4, 1), new MapPoint(0, 1)];
      gameTraffic.addObject("john", "truck1", points, 7);
    });
                    
    var lastMousePoint = new MapPoint(-1, -1);
    $(window).on('mousemove', function(e) {
        var point = e2MapPoint(e);
        if (lastMousePoint.x != point.x || lastMousePoint.y != point.y) {
            gameInteractionMap.clearMap();
            lastMousePoint = point;
            if(point.x >= 0 && point.x < calculator.mapWidth && point.y >= 0 && point.y < calculator.mapHeight) {
                 gameInteractionMap.drawTile(point);
            }
        }
    });
    $(window).on('click', function(e) {
        var point = e2MapPoint(e);
        if(point.x >= 0 && point.x < calculator.mapWidth && point.y >= 0 && point.y < calculator.mapHeight) {
             syncData("clicked", point);
        }
    });
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});

function e2MapPoint(e) {
    var tileWidth = calculator.tileWidth * calculator.canvasScale / 2;
    var tileHeight = calculator.tileHeight * calculator.canvasScale / 2;
    e.pageX = e.pageX - tileWidth / 2;
    e.pageY = e.pageY - tileHeight / 2 - calculator.canvasTopMargin * calculator.canvasScale/2 - tileHeight*(calculator.mapHeight-2)/2;
    var tileX = Math.round(e.pageX / tileWidth - e.pageY / tileHeight);
    var tileY = Math.round(e.pageX / tileWidth + e.pageY / tileHeight);

    return new MapPoint(tileX, tileY);
}
