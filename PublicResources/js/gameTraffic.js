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
    
        var points = [new MapPoint(0, 1), new MapPoint(2, 1), new MapPoint(2, 4), new MapPoint(4, 4), new MapPoint(4, 1), new MapPoint(0, 1)];
        this.addObject("suzanne", "car1", points, 7);
        
        
        var t = this;
        setTimeout(function(){
                   var points = [new MapPoint(0, 1), new MapPoint(10, 1)];
                   t.addObject("emily", "car2", points, 7);
        }, 2000);

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
