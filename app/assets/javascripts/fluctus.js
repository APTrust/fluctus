var activate_tabs = function() {
  $('ul.nav-tabs li:first').addClass('active');
  $('ul.nav-tabs + div.tab-content div.tab-pane:first').addClass('active');
};

var dropdown = function() {
    $('.dropdown-toggle').dropdown();
};

function add_form_classes() {
    $("#tabs-2 form").addClass("search-query-form form-inline clearfix navbar-form");
}

function select_pi_tab() {
    $("#tabs-2-link").click();
}

function fix_search_breadcrumb() {
    //$("a.btn-sm").removeClass("dropdown-toggle");
    //$("span.appliedFilter").removeClass("open");
}

$(document).ready(activate_tabs);
$(document).on('page:load', activate_tabs);
$(document).ready(dropdown);
$(document).on('page:load', dropdown);
$(document).ready(fix_search_breadcrumb);
$(document).on('page:load', fix_search_breadcrumb);