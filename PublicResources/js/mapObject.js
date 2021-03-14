//
//  File.swift
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

class GameMovableObject {
    constructor(screenX, screenY, speed, direction) {
        this.screenX = screenX
        this.screenY = screenY
        this.screenHeight = 400
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
