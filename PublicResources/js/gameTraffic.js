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
    
    stopTraffic() {
        this.movableObjects = [];
        this.clearMap();
    }
    
    addObject(id, type, mapPoints, speed) {
        this.movableObjects.push(new GameMovableObject(id, type, this.calculator, mapPoints, 400, speed));
        if(this.isRunning == false) {
            this.isRunning = true;
            var t = this;
            console.log("Traffic started");
            this.moveInterval = setInterval(function(){ t.updateFrame(); }, 50);
            this.cleanInterval = setInterval(function(){ t.cleanMovableObjects(); }, 150);
        }
    }

    clearMap() {
        var t = this;
        this.canvas.draw({
          fn: function(ctx) {
            ctx.clearRect(0, 0, t.calculator.canvasWidth, t.calculator.canvasHeight);
          }
        });
    }
    
    updateFrame() {
        this.clearMap();
        if( this.movableObjects.length == 0) {
            console.log("Traffic finished");
            clearInterval(this.moveInterval);
            clearInterval(this.cleanInterval);
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
            if(movableObject === undefined || movableObject.coordinates === undefined) { continue; }
            if(movableObject.coordinates.x === undefined || movableObject.coordinates.y === undefined) { continue; }
            movableObject.coordinates.x += movableObject.deltaX;
            movableObject.coordinates.y += movableObject.deltaY;
            movableObject.updateState();
        }
    }

    cleanMovableObjects() {
        this.movableObjects = this.movableObjects.filter(this.isValidMovableObject);
    }
    
    isValidMovableObject(movableObject) {
        return !movableObject.vehicleFinished
    }
}
