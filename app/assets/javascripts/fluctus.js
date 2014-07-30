var activate_tabs;
activate_tabs = function() {
  $('ul.nav-tabs li:first').addClass('active');
  $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

var dropdown;
dropdown = function() {
    $('.dropdown-toggle').dropdown();
};

$(document).ready(activate_tabs);
$(document).on('page:load', activate_tabs);
$(document).ready(dropdown);
$(document).on('page:load', dropdown)