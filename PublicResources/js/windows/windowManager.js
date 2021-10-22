//
//  windowManager.js
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//


function openWindow(name, path, width, height, mapX, mapY, singletonID = false) {
    return osOpenWindow(name, path, width, height, mapX, mapY, singletonID);
}

function openChildWindow(parentWindowIndex, name, path, width, height, singletonID = false) {
    var windowIndex = osOpenWindow(name, path, width, height, singletonID);
    osSetData(windowIndex, "parentWindowIndex", parentWindowIndex);
}

function setWindowTitle(windowIndex, title) {
    $("#appWindowTitle"+windowIndex).html(title);
}

function setWindowContent(windowIndex, content) {
    $("#appWindowContent"+windowIndex).html(content);
}

function setWindowFrame(windowIndex, src) {
    $("#appWindowContent"+windowIndex).html('<iframe id="frame'+windowIndex+'" class="appWindowFrame" src="' + src + '"></iframe>');
}

function setWindowActive(windowIndex) {
    osMakeWindowActive(windowIndex);
}

function setWindowLoading(windowIndex) {
    var loader = $('<i class="fa fa-refresh faa-spin animated appWindowTitlebarLoader" id="windowLoader'+windowIndex+'"></i>');
    $("#appWindowTitle"+windowIndex).prepend(loader);
    $("#appWindowContentLoader" + windowIndex).show();
}

function setWindowLoaded(windowIndex) {
    $("#windowLoader" + windowIndex).remove();
    $("#appWindowContentLoader" + windowIndex).hide();
}

function disableWindowResizing(windowIndex) {
    $("#appWindow" + windowIndex).resizable('disable');
}

function setWindowMinimumSize(windowIndex, minWidth, minHeight) {
    $("#appWindow" + windowIndex).attr("minWidth", minWidth);
    $("#appWindow" + windowIndex).attr("minHeight", minHeight);
}

function resizeWindow(windowIndex, width, height) {
    var appWindow = $("#appWindow" + windowIndex);

    var fullWidth = osGetSystemWindowWidth();
    var fullHeight = osGetSystemWindowHeight();
    if(width <= 1) {
        theWidth = Math.round(width * fullWidth);
    } else {
        theWidth = width;
    }
    if(height <= 1) {
        theHeight = Math.round(height * fullHeight);
    } else {
        theHeight = height;
    }
    
    if(theHeight >= fullHeight) {
        theHeight = fullHeight;
    }
    
    appWindow.width(theWidth);
    appWindow.height(theHeight);
    osUpdateWindowMeta(appWindow);
}

function centerWindowHorizontally(windowIndex) {
    osCenterWindow(windowIndex)
}

function centerWindowVertically(windowIndex) {
    osCenterWindowVertically(windowIndex)
}

function centerWindow(windowIndex) {
    centerWindowHorizontally(windowIndex);
    centerWindowVertically(windowIndex);
}

function closeWindow(windowIndex) {
    amountOfOpenedWindows--;
    $("#appWindow" + windowIndex).remove();
    closeAllChildWindows(windowIndex);
}

function closeAllChildWindows(parentWindowIndex) {
    while(childIndex = getWindowIndexByData("parentWindowIndex", parentWindowIndex)) {
        closeWindow(childIndex);
    }
}

function getWindow(windowIndex) {
    return $("#appWindow" + windowIndex);
}

function getWindowContent(windowIndex) {
    return $("#appWindowContent" + windowIndex);
}

function getWindowIndexByData(key, value) {
    
    var foundWindowIndex = false;
    $(".appWindow").each(function( index ) {
        var windowIndex = $(this).data("windowIndex");
        var data = $(this).data(key);
        if(data == value) {
            foundWindowIndex = windowIndex;
            return;
        }
    });
    return foundWindowIndex;
}

function positionWindow(windowIndex, mapX, mapY) {
    if (mapX >= 0 && mapY >= 0) {
        var coordinates = calculator.getCanvasCoordinates(new MapPoint(mapX, mapY));
        var appWindow = getWindow(windowIndex);
        coordinates.x += calculator.tileWidth/2;
        coordinates.y -= calculator.tileHeight;
        coordinates.x *=  calculator.canvasScale/2;
        coordinates.y *=  calculator.canvasScale/2;
        coordinates.x -= appWindow.width()/2;
        coordinates.y -= appWindow.height();
        coordinates.y -= $(window).scrollTop();
        coordinates.x -= $(window).scrollLeft();
        osPositionWindow(windowIndex, coordinates.x, coordinates.y);
    }
}

