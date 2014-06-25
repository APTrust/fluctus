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
    $("#"+purgeID).prop('disabled', false)
}

function purgeAction () {

}