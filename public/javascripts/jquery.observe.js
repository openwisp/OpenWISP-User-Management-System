/*
 jQuery.observe - jQuery plugin to allow to observe fields
 Version: 0.1

 Usage:
 $('something').observe(function(element, oldValue){alert('element had a value of:' + oldValue)}, 200);

 */

(function($){
    $.fn.observe = function(callback, period){
        return this.each(function(index, element){
            var element = $(element), value = $(element).val();
            element[0].focused = false;
            function checkForChange(){
                if ( element.val() != value ) callback.call( element, value );
                value = element.val();
            }
            setInterval(checkForChange, period * 1000);
        });
    }
})(jQuery);