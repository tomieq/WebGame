//
//  init.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

var gameMap;
var gameTraffic;

$( document ).ready(function() {
    var $canvasMap  = $('#canvasMap');
    gameMap = new GameMap($canvasMap, 25, 25, 0.25);
    gameMap.drawCoordinates();

    var $canvasTraffic  = $('#canvasTraffic');
    gameTraffic = new GameTraffic($canvasTraffic, 25, 25, 0.25);
    
    
    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
