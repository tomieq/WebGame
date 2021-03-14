var streetObjects = [];
var buildingObjects = [];
[START street]
streetObjects.push(new MapObject(new MapPoint({x}, {y}), "{path}", {imageWidth}, {imageHeight}));
[END street]
[START building]
buildingObjects.push(new MapObject(new MapPoint({x}, {y}), "{path}", {imageWidth}, {imageHeight}));
[END building]
gameStreetMap.setTiles(streetObjects, false);
gameBuildingsMap.setTiles(buildingObjects, false);
