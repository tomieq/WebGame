//
//  engine.js
//  
//
//  Created by Tomasz Kucharski on 18/03/2021.
//

var osWindowCounter = 0;
var windowsMeta = [];
var osTempSystemWidth = 0;
var osTempSystemHeight = 0;
var osSystemTopMenuHeight = 0;
var amountOfOpenedWindows = 0;


function osOpenWindow(name, path, width, height, mapX, mapY, singletonID = false) {
    
    amountOfOpenedWindows++;
    if(singletonID) {
        var openedWindowIndex = getWindowIndexByData("singletonID", singletonID);
        if(openedWindowIndex != false) {
            
            console.log("Restore app " + path);
            setTimeout(function() {
                osMakeWindowActive(openedWindowIndex);
            }, 200);
            return
        }
    }
    
    osWindowCounter++;
    var windowIndex = osWindowCounter;
    // open main window

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

    var appWindow = osBuildWindow(windowIndex, name, theWidth, theHeight);
    
    $('body').append(appWindow);

    if (mapX >= 0 && mapY >= 0) {
        var coordinates = calculator.getCanvasCoordinates(new MapPoint(mapX, mapY));
        coordinates.x += calculator.tileWidth/2;
        coordinates.y -= calculator.tileHeight;
        coordinates.x *=  calculator.canvasScale/2;
        coordinates.y *=  calculator.canvasScale/2;
        coordinates.x -= appWindow.width()/2;
        coordinates.y -= appWindow.height();
        coordinates.y -= $(window).scrollTop();
        coordinates.x -= $(window).scrollLeft();
        osPositionWindow(windowIndex, coordinates.x, coordinates.y);
    } else {
        osCenterWindow(windowIndex);
    }
    
    appWindow.resizable({
        start: function (event, ui) {
            osTempSystemWidth = osGetSystemWindowWidth();
            osTempSystemHeight = osGetSystemWindowHeight();
        },
        resize: function ( event, ui ) {
            
            var maxWidth = osTempSystemWidth - ui.position.left - 15;
            if(ui.size.width > maxWidth) {
                ui.size.width = maxWidth;
            }
            var minWidth = $(this).attr("minWidth");
            if(minWidth > 0 && ui.size.width < minWidth) {
                ui.size.width = minWidth;
            }
            var maxHeight = osTempSystemHeight - ui.position.top - 15;
            if(ui.size.height > maxHeight) {
                ui.size.height = maxHeight;
            }
            var minHeight = $(this).attr("minHeight");
            if(minHeight > 0 && ui.size.height < minHeight) {
                ui.size.height = minHeight;
            }
        },
        stop: function( event, ui ) {
                osUpdateWindowMeta($(this));
                var windowIndex = $(this).data("windowIndex");
                osNotifyAppWindowResized(windowIndex);
             }
        });
    appWindow.draggable({
        start: function(event, ui) {
            osTempSystemWidth = osGetSystemWindowWidth();
            osTempSystemHeight = osGetSystemWindowHeight();
            isDraggingMedia = true;
        },
        drag: function( event, ui ) {
            if(ui.position.left < 0 ) {
                ui.position.left = 0;
            }
            if(ui.position.top < osSystemTopMenuHeight ) {
                ui.position.top = osSystemTopMenuHeight;
            }
            var maxLeft = osTempSystemWidth - $(this).width();
            if(ui.position.left > maxLeft) {
                ui.position.left = maxLeft;
            }
            var maxTop = osTempSystemHeight - $(this).height();
            if(ui.position.top > maxTop) {
                ui.position.top = maxTop;
            }
        },
        stop: function(event, ui) {
            isDraggingMedia = false;
            osUpdateWindowMeta($(this));
        },
        cancel: '.appWindowContent'
    });

    

    if( singletonID ) {
        osSetData(windowIndex, "singletonID", singletonID);
        console.log("window is singleton with id=" + singletonID);
    }
    setWindowMinimumSize(windowIndex, 120, 100);
    osMakeWindowActive(windowIndex);
    runScripts(windowIndex, [path]);
    return windowIndex;
}

function osBuildWindow(windowIndex, name, width, height) {

    var appWindow = osBuildDiv(windowIndex, "appWindow");
    appWindow.width(width);
    appWindow.height(height);
    appWindow.attr("id", "appWindow" + windowIndex);
    appWindow.attr("minWidth", 0);
    appWindow.attr("minHeight", 0);
    appWindow.click(function() {osMakeWindowActive(appWindow.data("windowIndex"))});
    
    var titlebar = osBuildDiv(windowIndex, "appWindowTitlebar");
    var buttons = osBuildDiv(windowIndex, "appWindowButtons");
    var close = osBuildDiv(windowIndex, "appWindowClose");
    close.html('<a class="appWindowClosebutton" href="#"><span><strong>x</strong></span></a>');
    close.click(function(event){event.stopPropagation(); closeWindow(appWindow.data("windowIndex"));});

    buttons.append(close);
    titlebar.append(buttons);
    
    var windowTitle = osBuildDiv(windowIndex, "no");
    windowTitle.attr("id", "appWindowTitle" + windowIndex);
    windowTitle.html(name);
    titlebar.append(windowTitle);
    var content = osBuildDiv(windowIndex, "appWindowContent backgroundGray");
    content.attr("id", "appWindowContent" + windowIndex);
    var contentLoader = osBuildDiv(windowIndex, "appWindowContentLoader");
    contentLoader.attr("id", "appWindowContentLoader" + windowIndex);
    contentLoader.addClass("text-center");
    content.html('');
    appWindow.append(titlebar);
    appWindow.append(content);
    contentLoader.html('<i class="fa fa-2x fa-cog faa-spin animated"></i>');
    
    return appWindow;
}


function osBuildDiv(windowIndex, cssClass) {
    var dom = $("<div class='" + cssClass + "'></div>");
    dom.data("windowIndex", windowIndex);
    return dom;
}


function osCenterWindow(windowIndex) {
    var fullWidth = osGetSystemWindowWidth();
    
    var appWindow = $("#appWindow" + windowIndex);
    var realWindowWidth = appWindow.width();

    var x = Math.round(fullWidth/2 - realWindowWidth/2);
    appWindow.css({ left: x + 'px' });
    osUpdateWindowMeta(appWindow);
}


function osCenterWindowVertically(windowIndex) {
    var fullHeight = osGetSystemWindowHeight();
    
    var appWindow = $("#appWindow" + windowIndex);
    var realWindowHeight = appWindow.height();

    var y = Math.round(fullHeight/2 - realWindowHeight/2);
    appWindow.css({ top: y + 'px' });
    osUpdateWindowMeta(appWindow);
}

function osPositionWindow(windowIndex, x, y) {
    
    var appWindow = $("#appWindow" + windowIndex);
    var fullWidth = osGetSystemWindowWidth();
    var fullHeight = osGetSystemWindowHeight();
    
    if (x < 0) {
        x = 5;
    }
    if ( x + appWindow.width() > fullWidth ) {
        x = fullWidth - appWindow.width() - 5;
    }
    if (x < 0) {
        x = 5;
    }
    if ( y + appWindow.height() > fullHeight ) {
        y =  appWindow.height() - theHeight - 5;
    }
    if (y < 0) {
        y = 5;
    }

    appWindow.css({ left: x + 'px' });

    appWindow.css({ top: y + 'px' });
    osUpdateWindowMeta(appWindow);
}

function osMakeWindowActive(windowIndex) {
    $(".appWindow").each(function( index ) {
        var iWindowIndex = $(this).data("windowIndex");
        if( iWindowIndex != windowIndex ) {
            $(this).removeClass("appWindowActive");
            $("#appWindowContent" + iWindowIndex).addClass("blurred");
        } else {

            $(this).show();
            if( !$(this).hasClass("appWindowActive")) {
                $(this).addClass("appWindowActive");
            }
            $("#appWindowContent" + iWindowIndex).removeClass("blurred");
        }
    });
}

function getActiveWindowIndex() {
    return $(".appWindowActive").first().data("windowIndex");
}

function osAddWindowIndexToPath(windowIndex, path) {
    var pathWithIndex = osAddArgumentToPath(path, "windowIndex", windowIndex);
    pathWithIndex = osAddArgumentToPath(pathWithIndex, "rc", osRequestCounter);
    pathWithIndex = osAddArgumentToPath(pathWithIndex, "playerSessionID", playerSessionID);
    return pathWithIndex;
}


function osAddArgumentToPath(path, argumentName, argumentValue) {
    var pathWithArgument = path;

    // add argument if not present
    if(path.indexOf(argumentName + "=") == -1) {
        if(path.indexOf("?") !== -1) {
            pathWithArgument += '&';
        } else {
            pathWithArgument += '?';
        }
        pathWithArgument += argumentName + "=" + argumentValue;
    }
    return pathWithArgument;
}

function osDebugInfo(txt) {
    $("#debugWindow").html(txt);
    console.log(txt);
}

function osGetSystemWindowWidth() {
    return $(window).width();
}

function osGetSystemWindowHeight() {
    return $(window).height() - 10;
}

function osSetData(windowIndex, key, value) {
    getWindow(windowIndex).data(key, value);
}

function osGetData(windowIndex, key) {
    return getWindow(windowIndex).data(key);
}

function osUpdateWindowMeta(appWindow) {
    var windowIndex = appWindow.data("windowIndex");
    var position = appWindow.position();
    var meta = {'x': position.left,'y' : position.top, 'width' : appWindow.width(), 'height' : appWindow.height()};
    windowsMeta[windowIndex] = meta;
    osDebugInfo("Window " + windowIndex + "<br>X:" + meta.x + " Y:" + meta.y + "<br>W:" + meta.width + " H:" + meta.height);
}

function osGetRandomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}
