(function($) {
  $.fn.openseadragon = function() {
    var __osd_counter = 0;
    function generateOsdId() {
      __osd_counter++;
      
      return "Openseadragon" + __osd_counter;
    }

    $(this).each(function() {
      var $picture = $(this);
      $picture.addClass('openseadragon-viewer');
      
      if (typeof $picture.attr('id') === "undefined") {
        $picture.attr('id', generateOsdId());
      }

      var collectionOptions = $picture.data('openseadragon');
      var downloads = $picture.data('downloads');

      var sources = $picture.find('source[media="openseadragon"]');

      var tilesources = $.map(sources, function(e) {
        if ($(e).data('openseadragon')) {
          return $(e).data('openseadragon');
        } else {
          return $(e).attr('src');
        }
      });

      $picture.css('height', $picture.css('height'));

      viewer = OpenSeadragon(
        $.extend({ id: $picture.attr('id') }, collectionOptions, { tileSources: tilesources })
      )
      viewer.addHandler("page", function (data) {
        $("#" + collectionOptions['downloadButton']).attr('data-link', downloads[data.page]);
      });
     
      $picture.data('osdViewer', viewer);
    });

    return this;
  };
})(jQuery);
