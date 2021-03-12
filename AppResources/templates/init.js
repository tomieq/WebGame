var gameMap;
var gameTraffic;

$( document ).ready(function() {
    
    var calculator = new GameCalculator({mapWidth}, {mapHeight}, {mapScale});

    var canvasMap  = $('#canvasMap');
    gameMap = new GameMapInteractive(canvasMap, calculator);
    gameMap.drawCoordinates();
    
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
