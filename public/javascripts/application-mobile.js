$(document).bind("mobileinit", function(){
    $.mobile.loadingMessage=' ';
});

$(document).bind('pageshow', function(){
    $('select.disabled').selectmenu('disable');
    owums.toggleVerificationMethod();
});