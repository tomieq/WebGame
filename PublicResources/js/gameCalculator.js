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
        this.canvasWidth = ((this.mapWidth + this.mapHeight) * this.tileWidth/2);
        this.canvasHeight = ((this.mapHeight + this.mapWidth - 1) * this.tileHeight * 0.5 + this.canvasTopMargin);
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
