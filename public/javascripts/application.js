$(document).ready(function(){
    owums.toggleVerificationMethod();
});


var owums = {
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
    }
};

