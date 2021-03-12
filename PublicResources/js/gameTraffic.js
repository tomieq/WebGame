//
//  GameTraffic.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class GameTraffic {
    constructor(canvas, mapWidth, mapHeight, scale) {
        this.canvas = canvas
        this.canvasScale = scale;
        this.canvasTopMargin = 2100
        this.tileWidth = 600;
        this.tileHeight = 345;
        this.mapWidth = mapWidth;
        this.mapHeight = mapHeight;
        this.canvasWidth = ((this.mapWidth + this.mapHeight) * this.tileWidth/2);
        this.canvasHeight = ((this.mapHeight + this.mapWidth - 1) * this.tileHeight * 0.5 + this.canvasTopMargin);

        console.log("Canvas width: " + this.canvasWidth + " canvas height: " + this.canvasHeight);
        this.setupCanvas(this.canvas);
    }

    setupCanvas(canvas) {
        canvas.attr("width", this.canvasWidth * this.canvasScale);
        canvas.attr("height", this.canvasHeight * this.canvasScale);
        canvas.css("width", this.canvasWidth * this.canvasScale * 0.5);
        canvas.css("height", this.canvasHeight * this.canvasScale * 0.5);
        canvas.scaleCanvas({
            scale: this.canvasScale
        })
    }
}
