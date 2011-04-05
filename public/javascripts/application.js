var owums = {
    exists: function (selector) {
        return ($(selector).length > 0);
    }
};

// jQuery mobile init event (triggered for mobile version only)
$(document).bind("mobileinit", function(){
    $.mobile.loadingMessage = ' ';
});

$(document).bind('pageshow', function(){
    if (owums.exists('select.disabled')) {
        $('select.disabled').selectmenu('disable');
    }
});
