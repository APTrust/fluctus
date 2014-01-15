//= require blacklight/core
var facet_mine_behavior = function() {
  $('#aux-search-submit-header').hide();

  $('input[name="show"]').on("change", function(e) {
    $(this).closest('form').submit();
  });

};  

$(document).on('page:change', function() {
  facet_mine_behavior();
});
