function selected (category, filter) {
    $("#filter-"+category+" ul li").remove();
    var parent = $("#"+category+"-parent")[0];
    $(parent).addClass("facet_limit-active");
    jQuery('<li/>').appendTo("#filter-"+category+" ul");
    jQuery('<span/>', {
        class: "facet-label"
    }).appendTo("#filter-"+category+" ul li");
    jQuery('<span/>', {
        class: "selected",
        text: filter
    }).appendTo("#filter-"+category+" ul li span");
    $("#filter-title-"+category).click();
}

function callHandleSelected () {
    review_elements = $(".review");
    review_list = [];
    for(i = 0; i < review_elements.length; i++){
        if(review_elements[i].checked == true){
            review_list.push(review_elements[i].id);
        }
    }
    makeCall = confirm("Are you sure you want to mark as reviewed and/or purge these items?")
    if(makeCall == true){
        $.post('/itemresults/handle_selected', { review: review_list },
            function(data) {
                //alert(data);
            });
    }
}

function showReviewed () {
    show_reviewed = $("#toggleReviewed").prop('checked');
    $.post('/itemresults/show_reviewed', { show: show_reviewed },
        function(data){

        });
}

function addClassesToBtns () {
    $("#buttons input").addClass('btn');
    $("#buttons input").addClass('btn-normal');
}
