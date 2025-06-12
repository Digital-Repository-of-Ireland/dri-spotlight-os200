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
   
    var mapped_items = '<span class="mapped-count"><span class="badge badge-secondary">' + geojson_docs.features.length + '</span>' + ' location' + (geojson_docs.features.length !== 1 ? 's' : '') + ' mapped</span>';
    var mapped_caveat = '<span class="mapped-caveat">Only items with location data are shown below</span>';

    var sortAndPerPage = $('#sortAndPerPage');

    // Update page links with number of mapped items, disable sort, per_page, pagination
    if (sortAndPerPage.length) { // catalog#index and #map view
      var page_links = sortAndPerPage.find('.page-links');
      var result_count = page_links.find('.page-entries').find('strong').last().html();
      page_links.html('<span class="page-entries"><strong>' + result_count + '</strong> items found</span>' + mapped_items + mapped_caveat);
      sortAndPerPage.find('.dropdown-toggle').hide();
    } else { // catalog#show view
      $(this).before(mapped_items);
    }

    function getServiceJson(){
      const serviceRequest = new XMLHttpRequest();
      serviceRequest.open("GET", 'https://utility.arcgis.com/usrsvcs/servers/b5cbdd446d2e4f3fb31a76ec2d94b074/rest/services/MapGeniePremiumITM/MapServer?f=pjson&token=' + token, false);
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
        'https://utility.arcgis.com/usrsvcs/servers/b5cbdd446d2e4f3fb31a76ec2d94b074/rest/services/MapGeniePremiumITM/MapServer/tile/{z}/{y}/{x}' +
        '?f=psjon&token=' + token,
	projection: irishProjection,
        tileGrid: tileGrid,
      });

    const historicBasemapSource = new ol.source.XYZ({
        url:
        'https://utility.arcgis.com/usrsvcs/servers/7b9e02a664a54c2e938bed62911c7258/rest/services/MapGenie6InchFirstEditionColourITM/MapServer/tile/{z}/{y}/{x}' +
        '?f=pjson&token=' + token,
	projection: irishProjection,
        tileGrid: tileGrid,
      });

    const historicBWBasemapSource = new ol.source.XYZ({
        url:
        'https://utility.arcgis.com/usrsvcs/servers/b4da0f98915c4aeda18b89d704a3e4cf/rest/services/MapGenie6InchFirstEditionBlackWhiteITM/MapServer/tile/{z}/{y}/{x}' +
        '?f=pjson&token=' + token,
	projection: irishProjection,
        tileGrid: tileGrid,
      });

    const tileSource = new ol.source.TileWMS({
          url: $("#" + arg_opts.id).data('townland-source'),
          params: {'LAYERS': $("#" + arg_opts.id).data('townland-layer'), 'TILED': true},
          serverType: 'geoserver'
    })

    const circleDistanceMultiplier = 1;
    const circleFootSeparation = 28;
    const circleStartAngle = Math.PI / 2;

    const convexHullFill = new ol.style.Fill({
      color: 'rgba(255, 153, 0, 0.4)',
    });
    const convexHullStroke = new ol.style.Stroke({
      color: 'rgba(204, 85, 0, 1)',
      width: 1.5,
    });
    const outerCircleFill = new ol.style.Fill({
      color: 'rgba(255, 153, 102, 0.3)',
    });
    const innerCircleFill = new ol.style.Fill({
      color: 'rgba(255, 165, 0, 0.7)',
    });
    const textFill = new ol.style.Fill({
      color: '#fff',
    });
    const textStroke = new ol.style.Stroke({
      color: 'rgba(0, 0, 0, 0.6)',
      width: 3,
    });
    const innerCircle = new ol.style.Circle({
      radius: 14,
      fill: innerCircleFill,
    });
    const outerCircle = new ol.style.Circle({
      radius: 20,
      fill: outerCircleFill,
    });

    let clickFeature, clickResolution;

    /**
     * Computes the convex hull of a binary image using Andrew's Monotone Chain Algorithm
     * http://www.algorithmist.com/index.php/Monotone_Chain_Convex_Hull
     *
     * @param points - An array of points.
     * @param options - MCCH Algorithm options.
     * @return Coordinates of the convex hull in clockwise order
     */
    function monotoneChainConvexHull(points, options = {}) {
       const { sorted } = options;
       if (!sorted) {
           points = points.slice().sort(byXThenY);
       }
       const n = points.length;
       const result = new Array(n * 2);
       let k = 0;
       for (let i = 0; i < n; i++) {
          const point = points[i];
          while (k >= 2 && cw(result[k - 2], result[k - 1], point) <= 0) {
              k--;
          }
          result[k++] = point;
       }
       const t = k + 1;
       for (let i = n - 2; i >= 0; i--) {
           const point = points[i];
           while (k >= t && cw(result[k - 2], result[k - 1], point) <= 0) {
               k--;
           }
           result[k++] = point;
       }
       return result.slice(0, k - 1);
    }
    function cw(p1, p2, p3) {
        return (p2[1] - p1[1]) * (p3[0] - p1[0]) - (p2[0] - p1[0]) * (p3[1] - p1[1]);
    }
     function byXThenY(point1, point2) {
       if (point1[0] === point2[0]) {
           return point1[1] - point2[1];
       }
       return point1[0] - point2[0];
    }

    /**
     * Style for clusters with features that are too close to each other, activated on click.
     * @param {Feature} cluster A cluster with overlapping members.
     * @param {number} resolution The current view resolution.
     * @return {Style|null} A style to render an expanded view of the cluster members.
     */
    function clusterCircleStyle(cluster, resolution) {
      if (cluster !== clickFeature || resolution !== clickResolution) {
        return null;
      }
      const clusterMembers = cluster.get('features');
      const centerCoordinates = cluster.getGeometry().getCoordinates();
      return generatePointsCircle(
        clusterMembers.length,
        cluster.getGeometry().getCoordinates(),
        resolution
      ).reduce((styles, coordinates, i) => {
        const point = new ol.geom.Point(coordinates);
        const line = new ol.geom.LineString([centerCoordinates, coordinates]);
        styles.unshift(
          new ol.style.Style({
            geometry: line,
            stroke: convexHullStroke,
          })
        );
        styles.push(
          clusterMemberStyle(
            new ol.feature.Feature({
              ...clusterMembers[i].getProperties(),
              geometry: point,
            })
          )
        );
        return styles;
      }, []);
    }

    /**
     * From
     * https://github.com/Leaflet/Leaflet.markercluster/blob/31360f2/src/MarkerCluster.Spiderfier.js#L55-L72
     * Arranges points in a circle around the cluster center, with a line pointing from the center to
     * each point.
     * @param {number} count Number of cluster members.
     * @param {Array<number>} clusterCenter Center coordinate of the cluster.
     * @param {number} resolution Current view resolution.
     * @return {Array<Array<number>>} An array of coordinates representing the cluster members.
     */
    function generatePointsCircle(count, clusterCenter, resolution) {
      const circumference =
        circleDistanceMultiplier * circleFootSeparation * (2 + count);
      let legLength = circumference / (Math.PI * 2); //radius from circumference
      const angleStep = (Math.PI * 2) / count;
      const res = [];
      let angle;

      legLength = Math.max(legLength, 35) * resolution; // Minimum distance to get outside the cluster icon.

      for (let i = 0; i < count; ++i) {
        // Clockwise, like spiral.
        angle = circleStartAngle + i * angleStep;
        res.push([
          clusterCenter[0] + legLength * Math.cos(angle),
          clusterCenter[1] + legLength * Math.sin(angle),
        ]);
      }

      return res;
    }

    let hoverFeature;
    /**
     * Style for convex hulls of clusters, activated on hover.
     * @param {Feature} cluster The cluster feature.
     * @return {Style|null} Polygon style for the convex hull of the cluster.
     */
    function clusterHullStyle(cluster) {
      if (cluster !== hoverFeature) {
        return null;
      }
      const originalFeatures = cluster.get('features');
      const points = originalFeatures.map((feature) =>
        feature.getGeometry().getCoordinates()
      );
      console.log(points);
      return new ol.Style({
        geometry: new ol.geom.Polygon([monotoneChainConvexHull(points)]),
        fill: convexHullFill,
        stroke: convexHullStroke,
      });
    }

    function clusterStyle(feature) {
      const size = feature.get('features').length;
      return [
        new ol.style.Style({
          image: outerCircle,
        }),
        new ol.style.Style({
          image: innerCircle,
          text: new ol.style.Text({
            text: size.toString(),
            fill: textFill,
            stroke: textStroke,
          }),
        }),
      ];
    }

    // Layer displaying the convex hull of the hovered cluster.
    const clusterHulls = new ol.layer.Vector({
      source: clusterSource,
      style: clusterHullStyle,
    });

    // Layer displaying the expanded view of overlapping cluster members.
    const clusterCircles = new ol.layer.Vector({
      source: clusterSource,
      style: clusterCircleStyle,
    });

    const geojsonSource = new ol.source.Vector();
    const geojsonLayer = new ol.layer.Vector({
        title: 'Points',
        visible: true,
        source: geojsonSource,
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
        style: clusterStyle
    });
    
    geojsonSource.addFeatures(
          new ol.format.GeoJSON().readFeatures(geojson_docs, {
            dataProjection: 'EPSG:4326',
            featureProjection: 'EPSG:3857'
          })
        );

    map = new ol.Map({
           layers: [
    	       new ol.layer.Group({
               title: 'Base maps',
               layers: [
                 new ol.layer.Tile({
                   title: 'Historic Colour',
                   type: 'base',
                   visible: false,
                   source: historicBasemapSource
                 }),
                 new ol.layer.Tile({
                   title: 'Historic B&W',
                   type: 'base',
                   visible: false,
                   source: historicBWBasemapSource
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
             , clusterHulls, clusterCircles
           ],
          target: arg_opts.id,
          view: new ol.View({
            center: ol.proj.fromLonLat([-7.5,53.4]),
            zoom: 7,
            projection: 'EPSG:3857',
          }),
    });

    if (Array.isArray(geojsonSource.getFeatures())) {
      if (geojsonSource.getFeatures().length == 1) {
        map.getView().fit(geojsonSource.getExtent(), { padding: [50, 50, 50, 50] });
        map.getView().setZoom(12);
      } else if (geojsonSource.getFeatures().length > 1) {
        map.getView().fit(geojsonSource.getExtent(), { padding: [50, 50, 50, 50] });
      } 
    }

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

    map.on('pointermove', (event) => {
      clusters.getFeatures(event.pixel).then((features) => {
        if (features[0] !== hoverFeature) {
          // Display the convex hull on hover.
          hoverFeature = features[0];
          clusterHulls.setStyle(clusterHullStyle);
          // Change the cursor style to indicate that the cluster is clickable.
          map.getTargetElement().style.cursor =
            hoverFeature && hoverFeature.get('features').length > 1
              ? 'pointer'
              : '';
        }
      });
    });

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
              clickFeature = features[0].get('features')[0];
              var coord = map.getCoordinateFromPixel(event.pixel);
              var content = features[0].get('features')[0].get('popup');
              content_element.innerHTML = content;
              overlay.setPosition(coord);
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
