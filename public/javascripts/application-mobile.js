$(document).bind("mobileinit", function(){
    $.mobile.loadingMessage=' ';
    $.mobile.ajaxEnabled=false;
});

$(document).bind('pageshow', function(){
    $('select.disabled').selectmenu('disable');
    owums.toggleVerificationMethod();
    $('#footer').css({'position':'absolute','bottom':0,'left':0});
});