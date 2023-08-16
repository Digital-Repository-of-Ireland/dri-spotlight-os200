;(function( $ ) {
  $.fn.dri_openlayers_map = function(geojson_docs, token, arg_opts) {
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
   
    function getServiceJson(){
      const serviceRequest = new XMLHttpRequest();
      serviceRequest.open("GET", 'https://tiles-eu1.arcgis.com/FH5XCsx8rYXqnjF5/arcgis/rest/services/MapGeniePremiumITM/MapServer?f=json&token=' + token, false);
      serviceRequest.send();
      var serviceJson = serviceRequest.responseText;
      return JSON.parse(serviceJson);
    }
    
    const serviceJson = getServiceJson();
    const extent = [
          serviceJson.fullExtent.xmin,
          serviceJson.fullExtent.ymin,
          serviceJson.fullExtent.xmax,
          serviceJson.fullExtent.ymax,
        ];
    const origin = [
      serviceJson.tileInfo.origin.x,
      serviceJson.tileInfo.origin.y,
    ];
    const resolutions = serviceJson.tileInfo.lods.map(function(l) { return l.resolution; });
    const tileSize = [serviceJson.tileInfo.cols, serviceJson.tileInfo.rows];
    const tileGrid = new ol.tilegrid.TileGrid({
       extent: extent,
       origin: origin,
       resolutions: resolutions,
       tileSize: tileSize,
    });

    const osiBasemapSource = new ol.source.XYZ({
        url:
          'https://tiles-eu1.arcgis.com/FH5XCsx8rYXqnjF5/arcgis/rest/services/MapGeniePremiumITM/MapServer/tile/{z}/{y}/{x}' +
          '?token=' + token,
        projection: irishProjection,
        tileGrid: tileGrid,
      });

    const historicBasemapSource = new ol.source.XYZ({
        url:
          'https://tiles-eu1.arcgis.com/FH5XCsx8rYXqnjF5/arcgis/rest/services/MapGenie6InchFirstEditionColourITM/MapServer/tile/{z}/{y}/{x}' +
          '?token=' + token,
        projection: irishProjection,
        tileGrid: tileGrid,
      });

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

    const geojsonSource = new ol.source.Vector();
    const geojsonLayer = new ol.layer.Vector({
        title: 'Points',
        visible: true,
        source: geojsonSource,
        style: pointStyle 
    });

    var clusterSource = new ol.source.Cluster({
        distance: 35,
        source: geojsonSource
      });
    var styleCache = {};
    var clusters = new ol.layer.Vector({
        title: 'Points',
        visible: true,
        source: clusterSource,
        style: function(feature) {
          var size = feature.get('features').length;
          var style = styleCache[size];
          if (!style) {
            style = new ol.style.Style({
              image: new ol.style.Circle({
                radius: 10,
                stroke: new ol.style.Stroke({
                  color: '#fff'
                }),
                fill: new ol.style.Fill({
                  color: '#3399CC'
                })
              }),
              text: new ol.style.Text({
                text: size.toString(),
                fill: new ol.style.Fill({
                  color: '#fff'
                })
              })
            });
            styleCache[size] = style;
          }
          return style;
        },
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
                   source: historicBasemapSource
                 }),
                 new ol.layer.Tile({
                   title: 'OSi',
                   type: 'base',
                   visible: true,
                   source: osiBasemapSource
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
                 clusters
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

    map.on('click', (event) => {
      clusters.getFeatures(event.pixel).then((features) => {
        if (features.length > 0) {
          const clusterMembers = features[0].get('features');
          if (clusterMembers.length > 1) {
            // Calculate the extent of the cluster members.
            const extent = ol.extent.createEmpty();
            clusterMembers.forEach((feature) =>
              ol.extent.extend(extent, feature.getGeometry().getExtent())
            );
            const view = map.getView();
            const resolution = map.getView().getResolution();
            if (
              view.getZoom() === view.getMaxZoom() ||
              (ol.extent.getWidth(extent) < resolution && ol.extent.getHeight(extent) < resolution)
            ) {
              // Show an expanded view of the cluster members.
              clickFeature = features[0];
              clickResolution = resolution;
              clusterCircles.setStyle(clusterCircleStyle);
            } else {
              // Zoom to the extent of the cluster members.
              view.fit(extent, {duration: 500, padding: [50, 50, 50, 50]});
            }
          } else {
          var coord = map.getCoordinateFromPixel(event.pixel);
          var content = features[0].get('features')[0].get('popup');
          content_element.innerHTML = content;
          overlay.setPosition(coord);
          }
        }
      })
    });
  };
}( jQuery ));
