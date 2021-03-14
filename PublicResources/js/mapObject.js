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
    constructor(coordinates, speed, direction) {
        this.coordinates = coordinates
        this.imageHeight = 400
        this.image = "objects/car" + direction + ".png";
        
        var xMod = 0;
        var yMod = 0;
        switch (direction) {
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
        
        this.deltaX = xMod * speed * Math.cos(Math.PI/180 * 30);
        this.deltaY = yMod * speed * Math.sin(Math.PI/180 * -30);
    }
}
