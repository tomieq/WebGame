var gameStreetMap;
var gameInteractionMap;
var gameTraffic;
var gameBuildingsMap;

$( document ).ready(function() {
    
    var calculator = new GameCalculator({mapWidth}, {mapHeight}, {mapScale});

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

                    
    var mouseMapX = -1;
    var mouseMapY = -1;
    $(window).on('mousemove', function(e) {
    
        var tileWidth = calculator.tileWidth * calculator.canvasScale / 2;
        var tileHeight = calculator.tileHeight * calculator.canvasScale / 2;
        e.pageX = e.pageX - tileWidth / 2;
        e.pageY = e.pageY - tileHeight / 2 - calculator.canvasTopMargin/2;
        var tileX = Math.round(e.pageX / tileWidth - e.pageY / tileHeight);
        var tileY = Math.round(e.pageX / tileWidth + e.pageY / tileHeight);

        if (mouseMapX != tileX || mouseMapY != tileY) {
            gameInteractionMap.clearMap();
            mouseMapX = tileX;
            mouseMapY = tileY;
            if(tileX >= 0 && tileX < calculator.mapWidth && tileY >= 0 && tileY < calculator.mapHeight) {
            
                 gameInteractionMap.drawTile(new MapPoint(tileX, tileY));
            }
        }
    });
                    
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
