//
//  gameCalculator.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class GameCalculator {
    constructor(mapWidth, mapHeight, scale) {
        this.canvasScale = scale;
        this.canvasTopMargin = 2100
        this.tileWidth = 600;
        this.tileHeight = 345;
        this.mapWidth = mapWidth;
        this.mapHeight = mapHeight;
        this.canvasWidth = this.pow2ceil((this.mapWidth + this.mapHeight) * this.tileWidth/2);
        this.canvasHeight = this.pow2ceil((this.mapHeight + this.mapWidth - 1) * this.tileHeight * 0.5 + this.canvasTopMargin);
    }

    pow2ceil(v) {
        return v;
        /*
      var p = 2;
      while (v >>= 1) {
        p <<= 1;
      }
      return p;
         */
    }
                            
    setupCanvas(canvas) {
        console.log("Canvas width: " + this.canvasWidth + " canvas height: " + this.canvasHeight);

        canvas.attr("width", this.canvasWidth * this.canvasScale);
        canvas.attr("height", this.canvasHeight * this.canvasScale);
        canvas.css("width", this.canvasWidth * this.canvasScale * 0.5);
        canvas.css("height", this.canvasHeight * this.canvasScale * 0.5);
        canvas.scaleCanvas({
            scale: this.canvasScale
        })
    }

    getCanvasCoordinates(mapPoint) {
        var canvasX = ((mapPoint.x + mapPoint.y) * this.tileWidth * 0.5);
        var canvasY = ((this.mapWidth + mapPoint.y) * this.tileHeight * 0.5 - (mapPoint.x * this.tileHeight * 0.5) + this.canvasTopMargin);
        return new Coordinates(canvasX, canvasY)
    }
}
