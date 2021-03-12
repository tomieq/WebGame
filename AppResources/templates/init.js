var gameMap;
var gameTraffic;

$( document ).ready(function() {
    
    var calculator = new GameCalculator({mapWidth}, {mapHeight}, {mapScale});

    var canvasMap  = $('#canvasMap');
    gameMap = new GameMap(canvasMap, calculator);
    gameMap.drawCoordinates();

    var $canvasTraffic  = $('#canvasTraffic');
    gameTraffic = new GameTraffic($canvasTraffic, calculator);
    
    
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
