//
//  File.swift
//  
//
//  Created by Tomasz Kucharski on 12/03/2021.
//

class MapPoint {
    constructor(mapX, mapY) {
        this.x = mapX
        this.y = mapY
    }
}

class Coordinates {
    constructor(x, y) {
        this.x = x
        this.y = y
    }
}

class MapObject {
    constructor(mapPoint, imagePath, imageWidth, imageHeight) {
        this.mapPoint = mapPoint;
        this.imagePath = imagePath;
        this.imageWidth = imageWidth;
        this.imageHeight = imageHeight;
    }
}

class GameMovableObject {
    constructor(id, type, calculator, mapPoints, imageHeight, speed) {
        this.id = id;
        this.type = type;
        this.calculator = calculator;
        this.mapPoints = mapPoints;
        this.pathCounter = 0;
        this.imageHeight = imageHeight;
        this.speed = speed;
        this.direction = 0;
        this.coordinates = 0;
        this.endCoordinates = 0;
        this.image = "";
        this.applyNextPath();
    }
    
    updateState() {
        switch (this.direction) {
            case 1:
                if (this.coordinates.y >= this.endCoordinates.y) {
                    this.applyNextPath();
                }
                break;
            case 2:
                if (this.coordinates.x >= this.endCoordinates.x) {
                    this.applyNextPath();
                }
                break;
            case 3:
                if (this.coordinates.x <= this.endCoordinates.x) {
                    this.applyNextPath();
                }
                break;
            case 4:
                if (this.coordinates.y <= this.endCoordinates.y) {
                    this.applyNextPath();
                }
                break;
        }
    }
    
    applyNextPath() {
        if(this.pathCounter + 1 >= this.mapPoints.length ) {
            this.speed = 0;
            console.log("Vehicle " + this.id + " finished");
            return
        }
        var startPoint = this.mapPoints[this.pathCounter];
        var endPoint = this.mapPoints[this.pathCounter+1];
        this.coordinates = this.calculator.getCanvasCoordinates(startPoint);
        this.endCoordinates = this.calculator.getCanvasCoordinates(endPoint);
        this.pathCounter++;
        
        if( startPoint.x == endPoint.x ) {
            if ( startPoint.y > endPoint.y ) {
                this.direction = 3;
            } else {
                this.direction = 2;
            }
        }
        
        if( startPoint.y == endPoint.y ) {
            if ( startPoint.x > endPoint.x ) {
                this.direction = 1;
            } else {
                this.direction = 4;
            }
        }
        this.image = "objects/" + this.type + "." + this.direction + ".png";
        this.calculateDelta();
    }
                                              
    calculateDelta() {
        var xMod = 0;
        var yMod = 0;
        switch (this.direction) {
          case 1:
              xMod = -1;
              yMod = -1;
              break;
          case 2:
              xMod = 1;
              yMod = -1;
              break;
          case 3:
              xMod = -1;
              yMod = 1;
              break;
          case 4:
              xMod = 1;
              yMod = 1;
              break;
      }
      
      this.deltaX = xMod * this.speed * Math.cos(Math.PI/180 * 30);
      this.deltaY = yMod * this.speed * Math.sin(Math.PI/180 * -30);
  }
}
