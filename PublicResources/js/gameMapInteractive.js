//
//  GameMap.js
//
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class GameMovableObject {
    constructor(screenX, screenY) {
        this.screenX = screenX
        this.screenY = screenY
        this.screenHeight = 400
        this.speed = 5;
        this.mod = -1;
    }
}

class GameMapInteractive {
    constructor(canvas, calculator) {
        this.canvas = canvas;
        this.calculator = calculator;
        this.gameMap = 0;
        this.calculator.setupCanvas(this.canvas);
        this.drawGround();
        this.layers = [];
        this.layersScreenY = [];
        this.movableObjects = [];
        this.deltaX = Math.cos(Math.PI/180 * 30);
        this.deltaY = Math.sin(Math.PI/180 * -30);
        this.moveInterval = 0;
        
        var coordinates = this.calculator.getCanvasCoordinates(10, 1);
        var x = coordinates[0];
        var y = coordinates[1];
        this.movableObjects.push(new GameMovableObject(x, y));
        
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

    splitMapToLayers() {
        var layerIndex = 0;
        this.layers = [];

        var amountToTake = 1;
        for (var w = this.calculator.mapWidth; w--; w >= 0) {
            var mapX = w;
            var mapY = 0;
            this.layers[layerIndex] = [];
            
            var coordinates = this.calculator.getCanvasCoordinates(mapX, mapY);
            this.layersScreenY[layerIndex] = coordinates[1];
            for(var h = 0; h < amountToTake; h++) {
                
                var mapObject = this.findTileInObjectArray(this.gameMap, mapX, mapY);
                if (mapObject != undefined) {
                    this.layers[layerIndex].push(mapObject);
                    console.log("layer="+layerIndex+" "+mapX+"," + mapY);
                }
                mapX++;
                mapY++;
            }
            
            if (amountToTake < this.calculator.mapHeight) {
                amountToTake++;
            }
            layerIndex++;
        }
        
        var amountToTake = this.calculator.mapHeight - 1;
        for (var w = 1; w < this.calculator.mapHeight; w++) {
            var mapX = 0;
            var mapY = w;
            this.layers[layerIndex] = [];
            var coordinates = this.calculator.getCanvasCoordinates(mapX, mapY);
            this.layersScreenY[layerIndex] = coordinates[1];
            for(var h = amountToTake; h > 0; h--) {
                var mapObject = this.findTileInObjectArray(this.gameMap, mapX, mapY);
                if (mapObject != undefined) {
                    this.layers[layerIndex].push(mapObject);
                    console.log("layer="+layerIndex+" "+mapX+"," + mapY);
                }
                mapX++;
                mapY++;
            }
            amountToTake--;
            layerIndex++;
        }
    }
    
    setTiles(gameMap, fillWithGrass) {
        this.gameMap = gameMap;
        var imageSources = this.getImageResources(gameMap);

        Promise
        .all(imageSources.map(i => this.loadImage(i)))
        .then((images) => {
            var t = this;
            t.splitMapToLayers()
            clearInterval(t.moveInterval);
            //t.drawTiles();
            this.moveInterval = setInterval(function(){t.drawTiles();}, 50);
            setTimeout(function(){ clearInterval(t.moveInterval); }, 17000);

              setTimeout(function(){ t.addCar() }, 1000);
              setTimeout(function(){ t.addCar() }, 3000);
        });
    }
    
   addCar() {
       var coordinates = this.calculator.getCanvasCoordinates(10, 1);
       var x = coordinates[0];
       var y = coordinates[1];
       this.movableObjects.push(new GameMovableObject(x, y));
   }
    
    drawTiles() {
        this.clearMap();
        this.drawGround();
        this.drawCoordinates();
        for (var layerIndex = 0; layerIndex < this.layers.length; layerIndex++) {
           var layerScreenY = this.layersScreenY[layerIndex];

           for (var i = 0; i < this.movableObjects.length; i++) {
               var movableObject = this.movableObjects[i];
               if (movableObject.screenY < layerScreenY && movableObject.screenY > layerScreenY - this.calculator.tileHeight) {
                   //console.log("draw car in layer " + layerIndex);
                   this.canvas.drawImage({
                         source: "objects/car1.png",
                         x: movableObject.screenX,
                         y: (movableObject.screenY - movableObject.screenHeight),
                             width: 600,
                             height: 400,
                         fromCenter: false,
                         rotate: 0
                   });
                  movableObject.screenX += (movableObject.speed * movableObject.mod) * this.deltaX;
                  movableObject.screenY += (movableObject.speed * movableObject.mod) * this.deltaY;
               }
           }
            for (var i = 0; i < this.layers[layerIndex].length; i++) {
                var mapObject = this.layers[layerIndex][i];
                //console.log("draw "+mapObject.imagePath+" in layer " + layerIndex);
                this.setupTile(mapObject.mapX, mapObject.mapY, mapObject.imagePath, mapObject.imageWidth, mapObject.imageHeight);
            }
        }
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

    getImageResources(gameMap) {
        var imageSources = ["tiles/grass.png"];
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
