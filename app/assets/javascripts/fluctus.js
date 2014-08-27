var activate_tabs = function() {
  $('ul.nav-tabs li:first').addClass('active');
  $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

var dropdown = function() {
    $('.dropdown-toggle').dropdown();
};

var search_tabs = function() {
    $("#tabs").tabs();
};

$(document).ready(activate_tabs);
$(document).on('page:load', activate_tabs);
$(document).ready(dropdown);
$(document).on('page:load', dropdown);
$(document).ready(search_tabs);
$(document).on('page:load', search_tabs);