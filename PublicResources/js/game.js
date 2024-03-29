var secondsTimer;
var seconds = 0;


function updateWallet(value) {
    $("#wallet").html(value);
}

function updateGameDate(text, secondsLeft) {
    $("#gameDate").html(text);
    clearTimeout(secondsTimer);
    seconds = secondsLeft;
    displayCounter();
}

function displayCounter() {
    seconds--;
    if (seconds > 0) {
        secondsTimer = setTimeout(displayCounter, 1000);
    }
    if (seconds >= 0) {
        var left = secondsToText(seconds);
        $("#dateCounter").html(left);
    }
}

function secondsToText(secondsLeft) {
    var seconds = parseInt(secondsLeft % 60, 10);
    var minutes = parseInt((secondsLeft - seconds) / 60, 10);

    minutes = minutes < 10 ? "0" + minutes : minutes;
    seconds = seconds < 10 ? "0" + seconds : seconds;
    return minutes + ":" + seconds;
}


function mapClicked(x, y) {
    syncData("tileClicked", {x: x, y: y});
}

function gameDisconnected() {
    uiShowError('Game disconnected ', 50000);
    gameTraffic.stopTraffic();
    $("canvas").fadeOut(3000);
    $("#mainMenu").fadeOut(3000);
    $("#gameClock").fadeOut(3000);
    $(".appWindow").remove();
}

function publishOffer(windowIndex, submitUrl) {
    var price = $("#price" + windowIndex).val().replace(/\s/g, '');
    if(isNaN(price) || isNaN(parseFloat(price))){
        uiShowError("Please provide valid price", 5000);
    } else {
        runScripts(windowIndex, [submitUrl + "&price=" + price]);
    }
}

function highlightTiles(points, color) {
    gameInteractionMap.drawTiles(points, color);
}

function onlyNumbers(evt) {
  var theEvent = evt || window.event;

  // Handle paste
  if (theEvent.type === 'paste') {
      key = event.clipboardData.getData('text/plain');
  } else {
  // Handle key press
      var key = theEvent.keyCode || theEvent.which;
      key = String.fromCharCode(key);
  }
  var regex = /[0-9\s]|\./;
  if( !regex.test(key) ) {
    theEvent.returnValue = false;
    if(theEvent.preventDefault) theEvent.preventDefault();
  }
}
