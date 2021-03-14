//
//  GameTraffic.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class GameTraffic {
    constructor(canvas, calculator) {
        this.canvas = canvas;
        this.calculator = calculator;
        this.calculator.setupCanvas(this.canvas);
        this.movableObjects = [];
    
        var coordinates = this.calculator.getCanvasCoordinates(new MapPoint(0, 1));
        
        this.movableObjects.push(new GameMovableObject(coordinates, 7, 4));
        
        var coordinates = this.calculator.getCanvasCoordinates(new MapPoint(10, 1));
        
        this.movableObjects.push(new GameMovableObject(coordinates, 9, 1));
        // set interval for updating frames
        var t = this;
        this.moveInterval = setInterval(function(){ t.updateFrame(); }, 50);
        // stop timer after 17 seconds
        setTimeout(function(){ clearInterval(t.moveInterval); }, 22000);

    }

    updateFrame() {
        this.canvas.clearCanvas();
        if( this.movableObjects.lenght == 0) {
            clearInterval(this.moveInterval);
        }
        for (var i = 0; i < this.movableObjects.length; i++) {
            var movableObject = this.movableObjects[i];
                //console.log("draw car in layer " + movableObject.screenX + "," + movableObject.screenY);
                this.canvas.drawImage({
                      source: movableObject.image,
                      x: movableObject.coordinates.x,
                      y: (movableObject.coordinates.y - movableObject.imageHeight),
                          width: this.calculator.tileWidth,
                          height: movableObject.imageHeight,
                      fromCenter: false,
                      rotate: 0
                });
               movableObject.coordinates.x += movableObject.deltaX;
               movableObject.coordinates.y += movableObject.deltaY;
        }
        
    }

}
