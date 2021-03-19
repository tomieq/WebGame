//
//  loader.js
//  
//
//  Created by Tomasz Kucharski on 19/03/2021.
//

var osLoadedJS = [];
var osLoadedCSS = [];
var osRequestCounter = 0;

function requestStarted() {
    osRequestCounter++;
}

function loadCssAndJsAndHtmlThenRunScripts(windowIndex, cssFilePaths, jsFilePaths, htmlPath, scriptPaths, htmlSelector) {
    
    var pathsToLoad = [];
    for (var i = 0; i < cssFilePaths.length; i++) {
        var cssFilePath = cssFilePaths[i];
        if(!osLoadedCSS.contains(cssFilePath)) {
            osLoadedCSS.push(cssFilePath);
            pathsToLoad.push(cssFilePath);
        }
    }
    

    if(pathsToLoad.length > 0 ) {
        var countDown = pathsToLoad.length;
        setWindowLoading(windowIndex);
        for (var i = 0; i < pathsToLoad.length; i++) {

            requestStarted();
            var pathWithIndex = pathsToLoad[i];
            $.get(pathWithIndex, function(response) {

                var randomID = osGetRandomInt(1000, 9999);
                $('head').append('<style id="loadedTheme' + randomID +'"></style>');
                $('#loadedTheme' + randomID).text(response);
                countDown--;
                if(countDown == 0) {
                    setWindowLoaded(windowIndex);
                    loadJsAndHtmlThenRunScripts(windowIndex, jsFilePaths, htmlPath, scriptPaths, htmlSelector);
                }
             }).fail(function( jqxhr, settings, exception ) {
                    uiShowError( windowIndex + ': Error while loading CSS<br>' + exception);
              })
        }
    } else {
        loadJsAndHtmlThenRunScripts(windowIndex, jsFilePaths, htmlPath, scriptPaths, htmlSelector);
    }
}

function loadJsAndHtmlThenRunScripts(windowIndex, jsFilePaths, htmlPath, scriptPaths, htmlSelector) {

    var pathsToLoad = [];
    for (var i = 0; i < jsFilePaths.length; i++) {
        var jsFilePath = jsFilePaths[i];
        if(!osLoadedJS.contains(jsFilePath)) {
            osLoadedJS.push(jsFilePath);
            pathsToLoad.push(jsFilePath);
        }
    }
    
    if(pathsToLoad.length > 0 ) {
        var countDown = pathsToLoad.length;
        setWindowLoading(windowIndex);
        for (var i = 0; i < pathsToLoad.length; i++) {
            var script = document.createElement('script');
            script.onload = function () {
                //do stuff with the script
                countDown--;
                if(countDown == 0 ){
                    setWindowLoaded(windowIndex);
                    loadHtmlThenRunScripts(windowIndex, htmlPath, scriptPaths, htmlSelector);
                }
            };
            requestStarted();
            var jsFilePathPathWithIndex = osAddWindowIndexToPath(windowIndex, pathsToLoad[i]);
            script.src = jsFilePathPathWithIndex;
            document.head.appendChild(script);
        }
    } else {
        loadHtmlThenRunScripts(windowIndex, htmlPath, scriptPaths, htmlSelector);
    }
}

function loadHtmlThenRunScripts(windowIndex, htmlPath, scriptPaths, htmlSelector) {
    if( typeof htmlPath == 'string') {
        if(htmlSelector.length > 0) {
            var selector = htmlSelector;
        } else {
            var selector = "#appWindowContent" + windowIndex;
        }
        requestStarted();
        var htmlPathWithIndex = osAddWindowIndexToPath(windowIndex, htmlPath);
        $(selector).empty();
        setWindowLoading(windowIndex);
        $(selector).load( htmlPathWithIndex, function(response, status, xhr) {
            setWindowLoaded(windowIndex);
            if ( status == "error" ) {
                uiShowError( windowIndex + ': Error while loading HTML: ' +  + xhr.status );
            } else {
                runScripts(windowIndex, scriptPaths);
            }
        });
    } else {
        runScripts(windowIndex, scriptPaths);
        
    }
}

function runScripts(windowIndex, scriptPaths) {
    var countDown = scriptPaths.length;
    if(countDown > 0) {
        setWindowLoading(windowIndex);
        for (var i = 0; i < scriptPaths.length; i++) {
            console.log('GET ' + scriptPaths[i]);
            requestStarted();
            var pathWithIndex = osAddWindowIndexToPath(windowIndex, scriptPaths[i]);
            $.getScript(pathWithIndex)
              .done(function( script, textStatus ) {
              })
              .fail(function( jqxhr, settings, exception ) {
                    uiShowError( windowIndex + ': Error while loading script '+this.url+'<br>' + exception);
              }).always(function() {
                countDown--;
                if(countDown == 0) {
                     setWindowLoaded(windowIndex);
                }
              });
        }
    }
}

Array.prototype.contains = function(obj) {
    var i = this.length;
    while (i--) {
        if (this[i] === obj) {
            return true;
        }
    }
    return false;
}
