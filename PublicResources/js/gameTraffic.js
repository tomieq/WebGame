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
        this.isRunning = false;
    }
    
    addObject(id, type, mapPoints, speed) {
        this.movableObjects.push(new GameMovableObject(id, type, this.calculator, mapPoints, 400, speed));
        if(this.isRunning == false) {
            this.isRunning = true;
            var t = this;
            console.log("Traffic started");
            this.moveInterval = setInterval(function(){ t.updateFrame(); }, 50);
        }
    }

    updateFrame() {
        this.canvas.clearCanvas();
        if( this.movableObjects.length == 0) {
            console.log("Traffic finished");
            clearInterval(this.moveInterval);
            this.isRunning = false;
        }
        for (var i = 0; i < this.movableObjects.length; i++) {
            var movableObject = this.movableObjects[i];
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
        this.movableObjects = this.movableObjects.filter(this.isValidMovableObject);
    }

    isValidMovableObject(movableObject) {
        return movableObject.speed > 0;
    }
}
