var activate_tabs;
activate_tabs = function() {
  $('ul.nav-tabs li:first').addClass('active');
  $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

$(document).ready(activate_tabs);
$(document).on('page:load', activate_tabs);