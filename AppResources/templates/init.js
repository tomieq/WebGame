var gameStreetMap;
var gameTraffic;
var gameBuildingsMap;

$( document ).ready(function() {
    
    var calculator = new GameCalculator({mapWidth}, {mapHeight}, {mapScale});

    var canvasStreets  = $('#canvasStreets');
    gameStreetMap = new GameMap(canvasStreets, calculator);
    gameStreetMap.drawGround();
    gameStreetMap.drawCoordinates();
    
    var canvasBuildings  = $('#canvasBuildings');
    gameBuildingsMap = new GameMap(canvasBuildings, calculator);

    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
