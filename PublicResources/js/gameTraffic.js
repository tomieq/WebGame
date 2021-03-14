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
    
        var coordinates = this.calculator.getCanvasCoordinates(0, 1);
        var x = coordinates[0];
        var y = coordinates[1];
        
        this.movableObjects.push(new GameMovableObject(x, y, 7, 4));
        
        var coordinates = this.calculator.getCanvasCoordinates(10, 1);
        x = coordinates[0];
        y = coordinates[1];
        
        this.movableObjects.push(new GameMovableObject(x, y, 9, 1));
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
                      x: movableObject.screenX,
                      y: (movableObject.screenY - movableObject.screenHeight),
                          width: 600,
                          height: 400,
                      fromCenter: false,
                      rotate: 0
                });
               movableObject.screenX += movableObject.deltaX;
               movableObject.screenY += movableObject.deltaY;
        }
        
    }

}
