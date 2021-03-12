//
//  GameMap.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//


class MapObject {
    constructor(mapX, mapY, imagePath, imageWidth, imageHeight) {
        this.mapX = mapX;
        this.mapY = mapY;
        this.imagePath = imagePath;
        this.imageWidth = imageWidth;
        this.imageHeight = imageHeight;
    }
}

class GameMap {
    constructor(canvas, calculator) {
        this.canvas = canvas;
        this.calculator = calculator;
        
        this.calculator.setupCanvas(this.canvas)
        this.drawGround();
    }

    drawCoordinates() {
        for (var mapX = 0; mapX < this.calculator.mapWidth; mapX++) {
            for (var mapY = 0; mapY < this.calculator.mapHeight; mapY++) {
                var coordinates = this.calculator.getCanvasCoordinates(mapX, mapY);
                var canvasX = coordinates[0] + this.calculator.tileWidth * 0.5;
                var canvasY = coordinates[1] - this.calculator.tileHeight * 0.5;
                this.canvas.drawText({
                        fillStyle: '#9cf',
                        x: canvasX, y: canvasY,
                        fontSize: 66,
                        fontFamily: 'Verdana, sans-serif',
                        text: mapX + ',' + mapY
                });
            }
        }
    }

    clearMap() {
        this.canvas.clearCanvas();
    }

    drawTiles(gameMap, fillWithGrass) {

        var imageSources = this.getImageResources(gameMap, fillWithGrass);

        Promise
        .all(imageSources.map(i => this.loadImage(i)))
        .then((images) => {
            for (var mapX = this.calculator.mapWidth - 1; mapX >= 0 ; mapX--) {
                for (var mapY = 0; mapY < this.calculator.mapHeight; mapY++) {
                    var mapObject = this.findTileInObjectArray(gameMap, mapX, mapY);
                    if (mapObject != undefined) {
                        this.setupTile(mapObject.mapX, mapObject.mapY, mapObject.imagePath, mapObject.imageWidth, mapObject.imageHeight);
                    } else if (fillWithGrass) {
                        this.setupTile(mapX, mapY, "tiles/grass.png", 600, 400);
                    }
                }
            }
        });
    }

    drawGround() {
        var left = this.calculator.getCanvasCoordinates(0, 0);
        var right = this.calculator.getCanvasCoordinates(this.calculator.mapWidth - 1, this.calculator.mapHeight - 1);
        var top = this.calculator.getCanvasCoordinates(this.calculator.mapWidth - 1, 0);
        var bottom = this.calculator.getCanvasCoordinates(0, this.calculator.mapHeight - 1);


        var leftX = left[0];
        var leftY = left[1] - 0.5 * this.calculator.tileHeight;
        var bottomX = bottom[0] + this.calculator.tileWidth * 0.5;
        var bottomY = bottom[1];
        var rightX = right[0] + this.calculator.tileWidth;
        var rightY = right[1] - 0.5 * this.calculator.tileHeight;
        var topX = top[0] + 0.5 * this.calculator.tileWidth;
        var topY = top[1] - this.calculator.tileHeight;
        // rectangle
        
        this.canvas.drawLine({
                strokeStyle: '#42626a',
                strokeWidth: 10,
                x1: leftX, y1: leftY,
                x2: bottomX, y2: bottomY,
                x3: rightX, y3: rightY,
                x4: topX, y4: topY,
                closed: true
        });
        // grid
        var startX = leftX + 0.5 * this.calculator.tileWidth;
        var startY = leftY + 0.5 * this.calculator.tileHeight;
        var stopX = topX + 0.5 * this.calculator.tileWidth;
        var stopY = topY + 0.5 * this.calculator.tileHeight;
        for (var i = 0; i < this.calculator.mapHeight - 1; i++) {
            this.canvas.drawLine({
                    strokeStyle: '#42626a',
                    strokeWidth: 10,
                    x1: startX, y1: startY,
                    x2: stopX, y2: stopY
            });
            startX += 0.5 * this.calculator.tileWidth;
            stopX += 0.5 * this.calculator.tileWidth;
            startY += 0.5 * this.calculator.tileHeight;
            stopY += 0.5 * this.calculator.tileHeight;
        }
        var startX = leftX + 0.5 * this.calculator.tileWidth;
        var startY = leftY - 0.5 * this.calculator.tileHeight;
        var stopX = bottomX + 0.5 * this.calculator.tileWidth;
        var stopY = bottomY - 0.5 * this.calculator.tileHeight;
        for (var i = 0; i < this.calculator.mapWidth - 1; i++) {
            this.canvas.drawLine({
                    strokeStyle: '#42626a',
                    strokeWidth: 10,
                    x1: startX, y1: startY,
                    x2: stopX, y2: stopY
            });
            startX += 0.5 * this.calculator.tileWidth;
            stopX += 0.5 * this.calculator.tileWidth;
            startY -= 0.5 * this.calculator.tileHeight;
            stopY -= 0.5 * this.calculator.tileHeight;
        }

    }

    getImageResources(gameMap, fillWithGrass) {
        var imageSources = [];
        if (fillWithGrass) {
            imageSources.push("tiles/grass.png");
        }
        for (var i = 0; i < gameMap.length; i++) {
            var mapObject = gameMap[i];
            if (mapObject instanceof MapObject) {
                var path = mapObject.imagePath;
                if (!imageSources.includes(path)) {
                    imageSources.push(path);
                }
            }
        }
        return imageSources;
    }

    findTileInObjectArray(gameMap, mapX, mapY) {
        for (var i = 0; i < gameMap.length; i++) {
            var mapObject = gameMap[i];
            if (mapObject instanceof MapObject) {
                if (mapObject.mapX == mapX && mapObject.mapY == mapY) {
                    return mapObject;
                }
            }
        }
        return undefined;
    }

    setupTile(mapX, mapY, imagePath, imageWidth, imageHeight) {
        var coordinates = this.calculator.getCanvasCoordinates(mapX, mapY);
        var canvasX = coordinates[0];
        var canvasY = coordinates[1] - imageHeight;
        this.canvas.drawImage({
              source: imagePath,
              x: canvasX, y: canvasY,
                  width: imageWidth,
                  height: imageHeight,
              fromCenter: false,
              rotate: 0
        });
    }

    loadImage(imagePath) {
        return new Promise((resolve, reject) => {
            let image = new Image();
            image.addEventListener("load", () => {
                console.log("Loaded image " + imagePath);
                resolve(image);
            });
            image.addEventListener("error", (err) => {
                reject(err);
            });
            image.src = imagePath;
        });
    }
}
