
function updateWallet(value) {
    $("#wallet").html(value);
}

function updateGameDate(value) {
    $("#gameDate").html(value);
}

function mapClicked(x, y) {
    syncData("tileClicked", {x: x, y: y});
}
