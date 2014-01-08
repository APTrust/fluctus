//= require blacklight/core
(function($) {
  var facet_mine_behavior = function() {
    $('#aux-search-submit-header').hide();

    $('input[name="show_all"]').on("change", function(e) {
      $(this).closest('form').submit();
    });

  };  

  Blacklight.onLoad(function() {
    facet_mine_behavior();
  })
})(jQuery);

