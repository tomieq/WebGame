
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

function numberWithSpaces(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, " ");
}

function publishOffer(windowIndex, submitUrl) {
    var price = $("#price" + windowIndex).val().replace(/\s/g, '');
    if(isNaN(price) || isNaN(parseFloat(price))){
        uiShowError("Please provide valid price", 5000);
    } else {
        runScripts(windowIndex, [submitUrl + "&price=" + price]);
    }
}
