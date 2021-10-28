//
//  GameMap.js
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class GameMap {
    constructor(canvas, calculator) {
        this.canvas = canvas;
        this.calculator = calculator;
        
        this.calculator.setupCanvas(this.canvas)
    }

    drawCoordinates() {
        for (var mapX = 0; mapX < this.calculator.mapWidth; mapX++) {
            for (var mapY = 0; mapY < this.calculator.mapHeight; mapY++) {
                var coordinates = this.calculator.getCanvasCoordinates(new MapPoint(mapX, mapY));
                var canvasX = coordinates.x + this.calculator.tileWidth * 0.5;
                var canvasY = coordinates.y - this.calculator.tileHeight * 0.5;
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
        var t = this;
        this.canvas.draw({
          fn: function(ctx) {
            ctx.clearRect(0, 0, t.calculator.canvasWidth, t.calculator.canvasHeight);
          }
        });
    }

    setTiles(gameMap, fillWithGrass) {

        var imageSources = this.getImageResources(gameMap, fillWithGrass);

        Promise
        .all(imageSources.map(i => this.loadImage(i)))
        .then((images) => {
            this.clearMap();
            for (var mapX = this.calculator.mapWidth - 1; mapX >= 0 ; mapX--) {
                for (var mapY = 0; mapY < this.calculator.mapHeight; mapY++) {
                    var mapObject = this.findTileInObjectArray(gameMap, new MapPoint(mapX, mapY));
                    if (mapObject != undefined) {
                        this.setupTile(mapObject.mapPoint, mapObject.imagePath, mapObject.imageWidth, mapObject.imageHeight);
                    } else if (fillWithGrass) {
                        this.setupTile(new MapPoint(mapX, mapY), "tiles/grass.png", 600, 400);
                    }
                }
            }
        });
    }
    
    
    drawTiles(mapPoints, color) {
        for (var i = 0; i < mapPoints.length; i++) {
            this.drawTile(mapPoints[i], color);
        }
    }

    drawTile(mapPoint, color) {
        var coordinates = this.calculator.getCanvasCoordinates(mapPoint);
        var t = this;
        this.canvas.draw({
          fn: function(ctx) {
            ctx.beginPath();
            ctx.fillStyle = color;
            ctx.moveTo(coordinates.x, coordinates.y - 0.5 * t.calculator.tileHeight);
            ctx.lineTo(coordinates.x + t.calculator.tileWidth * 0.5, coordinates.y);
            ctx.lineTo(coordinates.x + t.calculator.tileWidth, coordinates.y - 0.5 * t.calculator.tileHeight);
            ctx.lineTo(coordinates.x + t.calculator.tileWidth * 0.5, coordinates.y - t.calculator.tileHeight);
            ctx.stroke();
            ctx.fill();
            ctx.closePath();
          }
        });
    }
    
    drawGrass() {
        var left = this.calculator.getCanvasCoordinates(new MapPoint(0, 0));
        var right = this.calculator.getCanvasCoordinates(new MapPoint(this.calculator.mapWidth - 1, this.calculator.mapHeight - 1));
        var top = this.calculator.getCanvasCoordinates(new MapPoint(this.calculator.mapWidth - 1, 0));
        var bottom = this.calculator.getCanvasCoordinates(new MapPoint(0, this.calculator.mapHeight - 1));
        
        var leftX = left.x;
        var leftY = left.y - 0.5 * this.calculator.tileHeight;
        var bottomX = bottom.x + this.calculator.tileWidth * 0.5;
        var bottomY = bottom.y;
        var rightX = right.x + this.calculator.tileWidth;
        var rightY = right.y - 0.5 * this.calculator.tileHeight;
        var topX = top.x + 0.5 * this.calculator.tileWidth;
        var topY = top.y - this.calculator.tileHeight;
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
        
        this.canvas.draw({
          fn: function(ctx) {
              let region = new Path2D();
              region.moveTo(leftX, leftY);
              region.lineTo(bottomX, bottomY);
              region.lineTo(rightX, rightY);
              region.lineTo(topX, topY);
              region.closePath();

              // Fill path
              ctx.fillStyle = '#9baa49';
              ctx.fill(region);
          }
        });
    }
    
    drawGround() {
        var left = this.calculator.getCanvasCoordinates(new MapPoint(0, 0));
        var right = this.calculator.getCanvasCoordinates(new MapPoint(this.calculator.mapWidth - 1, this.calculator.mapHeight - 1));
        var top = this.calculator.getCanvasCoordinates(new MapPoint(this.calculator.mapWidth - 1, 0));
        var bottom = this.calculator.getCanvasCoordinates(new MapPoint(0, this.calculator.mapHeight - 1));


        var leftX = left.x;
        var leftY = left.y - 0.5 * this.calculator.tileHeight;
        var bottomX = bottom.x + this.calculator.tileWidth * 0.5;
        var bottomY = bottom.y;
        var rightX = right.x + this.calculator.tileWidth;
        var rightY = right.y - 0.5 * this.calculator.tileHeight;
        var topX = top.x + 0.5 * this.calculator.tileWidth;
        var topY = top.y - this.calculator.tileHeight;
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

    findTileInObjectArray(gameMap, mapPoint) {
        for (var i = 0; i < gameMap.length; i++) {
            var mapObject = gameMap[i];
            if (mapObject instanceof MapObject) {
                if (mapObject.mapPoint.x == mapPoint.x && mapObject.mapPoint.y == mapPoint.y) {
                    return mapObject;
                }
            }
        }
        return undefined;
    }

    setupTile(mapPoint, imagePath, imageWidth, imageHeight) {
        var coordinates = this.calculator.getCanvasCoordinates(mapPoint);
        var canvasX = coordinates.x;
        var canvasY = coordinates.y - imageHeight;
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
