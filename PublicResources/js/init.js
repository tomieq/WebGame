//
//  init.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

var gameMap;

$( document ).ready(function() {
    var $canvas  = $('#canvasMap');
    gameMap = new GameMap($canvas, 12, 12);
    gameMap.drawCoordinates();

    $.getScript( "js/loadMap.js", function( data, textStatus, jqxhr ) {
      console.log( "Load was performed." );
    });

});
