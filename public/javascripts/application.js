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

    path: function(path) {
        var _curr = window.location.pathname;
        var _params = window.location.search;
        if (path.charAt(0) === '/') {
            if (_curr.substr(1, owums.subUri.length) === owums.subUri) {
                return '/'+owums.subUri+path+_params;
            } else {
                return path+_params;
            }
        } else {
            return _curr+'/'+path+_params;
        }
    }
};

