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
    constructor(canvas, mapWidth, mapHeight) {
        this.canvas = canvas
        this.canvasScale = 0.25;
        this.canvasTopMargin = 2100
        this.tileWidth = 600;
        this.tileHeight = 345;
        this.mapWidth = mapWidth;
        this.mapHeight = mapHeight;
        this.canvasWidth = ((this.mapWidth + this.mapHeight) * this.tileWidth/2);
        this.canvasHeight = ((this.mapHeight + this.mapWidth - 1) * this.tileHeight * 0.5 + this.canvasTopMargin);

        console.log("Canvas width: " + this.canvasWidth + " canvas height: " + this.canvasHeight);
        this.canvas.attr("width", this.canvasWidth * this.canvasScale);
        this.canvas.attr("height", this.canvasHeight * this.canvasScale);
        this.canvas.css("width", this.canvasWidth * this.canvasScale * 0.5);
        this.canvas.css("height", this.canvasHeight * this.canvasScale * 0.5);
        this.canvas.scaleCanvas({
            scale: this.canvasScale
            })
        this.drawGround();
    }

    getCanvasCoordinates(mapX, mapY) {

        var canvasX = ((mapX + mapY) * this.tileWidth * 0.5);
        var canvasY = ((this.mapWidth + mapY) * this.tileHeight * 0.5 - (mapX * this.tileHeight * 0.5) + this.canvasTopMargin);
        return [canvasX, canvasY]
    }

    drawCoordinates() {
        for (var mapX = 0; mapX < this.mapWidth; mapX++) {
            for (var mapY = 0; mapY < this.mapHeight; mapY++) {
                var coordinates = this.getCanvasCoordinates(mapX, mapY);
                var canvasX = coordinates[0] + this.tileWidth * 0.5;
                var canvasY = coordinates[1] - this.tileHeight * 0.5;
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
            for (var mapX = this.mapWidth - 1; mapX >= 0 ; mapX--) {
                for (var mapY = 0; mapY < this.mapHeight; mapY++) {
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
        var left = this.getCanvasCoordinates(0, 0);
        var right = this.getCanvasCoordinates(this.mapWidth - 1, this.mapHeight - 1);
        var top = this.getCanvasCoordinates(this.mapWidth - 1, 0);
        var bottom = this.getCanvasCoordinates(0, this.mapHeight - 1);


        var leftX = left[0];
        var leftY = left[1] - 0.5 * this.tileHeight;
        var bottomX = bottom[0] + this.tileWidth * 0.5;
        var bottomY = bottom[1];
        var rightX = right[0] + this.tileWidth;
        var rightY = right[1] - 0.5 * this.tileHeight;
        var topX = top[0] + 0.5 * this.tileWidth;
        var topY = top[1] - this.tileHeight;
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
        var startX = leftX + 0.5 * this.tileWidth;
        var startY = leftY + 0.5 * this.tileHeight;
        var stopX = topX + 0.5 * this.tileWidth;
        var stopY = topY + 0.5 * this.tileHeight;
        for (var i = 0; i < this.mapHeight - 1; i++) {
            this.canvas.drawLine({
                    strokeStyle: '#42626a',
                    strokeWidth: 10,
                    x1: startX, y1: startY,
                    x2: stopX, y2: stopY
            });
            startX += 0.5 * this.tileWidth;
            stopX += 0.5 * this.tileWidth;
            startY += 0.5 * this.tileHeight;
            stopY += 0.5 * this.tileHeight;
        }
        var startX = leftX + 0.5 * this.tileWidth;
        var startY = leftY - 0.5 * this.tileHeight;
        var stopX = bottomX + 0.5 * this.tileWidth;
        var stopY = bottomY - 0.5 * this.tileHeight;
        for (var i = 0; i < this.mapWidth - 1; i++) {
            this.canvas.drawLine({
                    strokeStyle: '#42626a',
                    strokeWidth: 10,
                    x1: startX, y1: startY,
                    x2: stopX, y2: stopY
            });
            startX += 0.5 * this.tileWidth;
            stopX += 0.5 * this.tileWidth;
            startY -= 0.5 * this.tileHeight;
            stopY -= 0.5 * this.tileHeight;
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
        var coordinates = this.getCanvasCoordinates(mapX, mapY);
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
