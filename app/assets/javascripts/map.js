proj4.defs(
  'EPSG:2157','+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=0.99982 +x_0=600000 +y_0=750000 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +type=crs'
);
ol.proj.proj4.register(proj4);
const irishProjection = new ol.proj.Projection({
        code: 'EPSG:2157',
        extent: [421849.81, 515251.59, 785108.1, 968015.39]
});

const parser = new ol.format.WMTSCapabilities();
let map;

function getCapabilities(file, layer, matrixSet){
  var request = new XMLHttpRequest();
  request.open("GET", file, false);
  request.send();
  var xml = request.responseXML;
  const result = parser.read(xml);
  const options = ol.source.WMTS.optionsFromCapabilities(result, {
      layer: layer,
      matrixSet: matrixSet,
      projection: irishProjection
    });
  return options;
}
let basemapCapabilities = getCapabilities('/data/WMTSCapabilitiesBM.xml', 'ITM_basemap_ms_premium', 'default028mm');
let historicCapabilities = getCapabilities('/data/WMTSCapabilities.xml', 'ITM_historic_6inch_cl', 'default028mm');

const tileSource = new ol.source.TileWMS({
      url: $('#map').data('townland-source'),
      params: {'LAYERS': $('#map').data('townland-layer'), 'TILED': true},
      serverType: 'geoserver'
})

map = new ol.Map({
       layers: [
	 new ol.layer.Group({
           title: 'Base maps',
           layers: [
             new ol.layer.Tile({
               title: 'Historic',
               type: 'base',
               visible: false,
               source: new ol.source.WMTS(historicCapabilities)
             }),
             new ol.layer.Tile({
               title: 'OSi',
               type: 'base',
               visible: true,
               source: new ol.source.WMTS(basemapCapabilities)
             })
	   ]
         }),
	 new ol.layer.Group({
           title: 'Overlays',
           layers: [
             new ol.layer.Tile({
	       title: 'Townlands',
	       visible: false,
               opacity: 0.3,
	       source: tileSource,
	     })
	   ]
         })
       ],
      target: 'map',
      view: new ol.View({
        center: ol.proj.fromLonLat([-7.5,53.4]),
        zoom: 7,
        projection: 'EPSG:3857'
      }),
});

var layerSwitcher = new LayerSwitcher({
  groupSelectStyle: 'children' // Can be 'children' [default], 'group' or 'none'
});
map.addControl(layerSwitcher);
