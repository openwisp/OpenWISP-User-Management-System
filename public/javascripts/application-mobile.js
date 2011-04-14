$(document).bind("mobileinit", function(){
    $.mobile.loadingMessage=' ';
});

$(document).bind('pageshow', function(){
    $('select.disabled').selectmenu('disable');
    owums.toggleVerificationMethod();
});

$(document).bind('pageshow', function(){
    $('.locale_link').bind('click', function() {
        $(document).one('pagehide', function(){
            $('[data-url=""]').remove();
            $('[data-url="/"]').remove();
        });
        $('.ui-page').not('.ui-page-active').remove();
    });
});

