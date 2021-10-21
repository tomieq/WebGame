
function updateWallet(value) {
    $("#wallet").html(value);
}

function updateGameDate(value) {
    $("#gameDate").html(value);
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
}
