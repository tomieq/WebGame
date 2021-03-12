//
//  init.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

var gameMap;
var gameTraffic;

$( document ).ready(function() {
    
    var calculator = new GameCalculator(25, 25, 0.25);

    var canvasMap  = $('#canvasMap');
    gameMap = new GameMap(canvasMap, calculator);
    gameMap.drawCoordinates();

    var $canvasTraffic  = $('#canvasTraffic');
    gameTraffic = new GameTraffic($canvasTraffic, 25, 25, 0.25);
    
    
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
