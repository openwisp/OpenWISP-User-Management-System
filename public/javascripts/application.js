$(document).ready(function(){
    owums.toggleVerificationMethod();
});


var owums = {
    exists: function (selector) {
        return ($(selector).length > 0);
    },

    //Change verification methods on signup
    toggleVerificationMethod: function() {
        $('[id$=verification_method]').change(function(){
            $('.verification-block').toggle();
        });
    }
};

