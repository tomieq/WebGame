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
    
        var points = [new MapPoint(0, 1), new MapPoint(2, 1), new MapPoint(2, 4), new MapPoint(4, 4), new MapPoint(4, 1), new MapPoint(0, 1)];
        
        this.movableObjects.push(new GameMovableObject(this.calculator, points, 400, 7));
        
        // set interval for updating frames
        var t = this;
        this.moveInterval = setInterval(function(){ t.updateFrame(); }, 50);
        // stop timer after 17 seconds
        setTimeout(function(){ clearInterval(t.moveInterval); }, 52000);

    }

    updateFrame() {
        this.canvas.clearCanvas();
        if( this.movableObjects.length == 0) {
            console.log("Traffic finished");
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
            movableObject.updateState();
        }
        this.movableObjects = this.movableObjects.filter(this.validMovableObject);
    }

    validMovableObject(movableObject) {
        return movableObject.speed > 0;
    }
}
