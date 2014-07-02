function statusToggle () {
    $("#status").toggle();
}

function stageToggle () {
    $("#stage").toggle();
}

function actionToggle () {
    $("#action").toggle();
}

function institutionToggle () {
    $("#institution").toggle();
}

function reviewAction (id) {
    purgeID = "p_"+id;
    $("#"+purgeID).prop('disabled', false);
}

function callHandleSelected () {
    review_elements = $(".review");
    review_list = [];
    for(i = 0; i < review_elements.length; i++){
        if(review_elements[i].checked == true){
            review_list.push(review_elements[i].id);
        }
    }
    purge_elements = $(".purge");
    purge_list = [];
    for(i = 0; i < purge_elements.length; i++){
        if(purge_elements[i].checked == true){
            purge_list.push(purge_elements[i].id);
        }
    }
    $.post('/itemresults/handle_selected', { review: review_list, purge: purge_list },
        function(data) {
            //alert(data);
        });

}