$(document).ready(function(){
    owums.toggleVerificationMethod();
});


var owums = {
    subUri: 'owums',

    exists: function (selector) {
        return ($(selector).length > 0);
    },

    hideWhenJsIsAvailable: function(selector) {
        if ($.support.ajax) {
            $(document).ready(function(){
                $(selector).hide();
            });
            $(document).ajaxComplete(function(){
                $(selector).hide();
            });
        }
    },

    //Change verification methods on signup
    toggleVerificationMethod: function() {
        $('[id$=verification_method]').change(function(){
            $('.verification-block').toggle();
        });
    },

    jsonPath: function(path) {
        if (path[0] === '/') {
            if (window.location.pathname.substr(1, owums.subUri.length) === owums.subUri) {
                return '/'+owums.subUri+path;
            } else {
                return path;
            }
        } else {
            return window.location.pathname+'/'+path;
        }
    }
};

