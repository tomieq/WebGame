//
//  engine.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

$( document ).ready(function() {
    var $canvas  = $('#canvasMap');
    var map = new GameMap($canvas, 10, 10);
    map.drawCoordinates();
});
