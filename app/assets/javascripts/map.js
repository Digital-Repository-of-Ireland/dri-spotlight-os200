;(function( $ ) {
  $.fn.dri_openlayers_map = function(geojson_docs, arg_opts) {
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

    let pointStyle = new ol.style.Style({
                       image: new ol.style.Circle({
                       radius: 5,
                       fill: new ol.style.Fill({
                         color: [255, 255, 255, 0.3]
                       }),
                       stroke: new ol.style.Stroke({color: '#cb1d1d', width: 2})
                       })
    })

    var geojsonSource = new ol.source.Vector();
    var geojsonLayer = new ol.layer.Vector({
        title: 'Points',
        visible: true,
        source: geojsonSource,
        style: pointStyle 
    });

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
    	           }),
                 geojsonLayer
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

    geojsonSource.addFeatures(
          new ol.format.GeoJSON().readFeatures(geojson_docs, {
            dataProjection: 'EPSG:4326',
            featureProjection: map.getView().getProjection()
          })
        );

    var layerSwitcher = new LayerSwitcher({
      groupSelectStyle: 'children' // Can be 'children' [default], 'group' or 'none'
    });
    map.addControl(layerSwitcher);

    var
        container = document.getElementById('popup'),
        content_element = document.getElementById('popup-content'),
        closer = document.getElementById('popup-closer');

    closer.onclick = function() {
        overlay.setPosition(undefined);
        closer.blur();
        return false;
    };
    var overlay = new ol.Overlay({
        element: container,
        autoPan: true,
        offset: [0, -10]
    });
    map.addOverlay(overlay);

    map.on('click', function(evt){
        var feature = map.forEachFeatureAtPixel(evt.pixel,
          function(feature, layer) {
            return feature;
          });
        if (feature) {
            var geometry = feature.getGeometry();
            var coord = geometry.getCoordinates();
            
            var content = feature.get('placename');
            
            content_element.innerHTML = content;
            overlay.setPosition(coord);
        }
    });
  };
}( jQuery ));
