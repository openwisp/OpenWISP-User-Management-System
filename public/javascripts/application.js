/*
# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

$(document).ready(function(){
    owums.ajaxQuickSearch();
    owums.ajaxLoading();
    owums.loadCheckboxWarnings();
    owums.hideWhenJsIsAvailable('.no_js');
    owums.hideWhenGraphsAreAvailable('.no_graphs');
    owums.initNotice();
    owums.initRegistration();
    owums.initCreditCardOverlay();
    owums.initUserForm();
    owums.initMenuAdjustments();
    owums.initSelectable();
});

$.fn.centerElement = function(){
    var el = $(this);
    el.css('top', ($(window).height() - (el.height() + parseInt(el.css('padding-top')) + parseInt(el.css('padding-bottom'))) ) / 2)
    .css('left', ($(window).width() - (el.width() + parseInt(el.css('padding-left')) + parseInt(el.css('padding-right'))) ) / 2);
    return el;
}
$.fn.togglePop = function(speed){
    speed = speed || 150;
    var el = $(this);
    el.centerElement();
    (el.is(':visible')) ? el.fadeOut(speed) : el.fadeIn(speed);
    return el;
}
$.fn.toggleMessage = function(message, speed){
    var el = $(this);
    if(!el.is(':visible')){
        el.html(message);
    }
    el.togglePop(speed);
    el.css('top', parseInt(el.css('top')) + 80);
}

var owums = {
    subUri: 'owums',  // overridden in main layout
    quickSearchDiv: '#quicksearch',
    loadingDiv: '#loading',

    exists: function(selector) {
        return ($(selector).length > 0);
    },

    initMenuAdjustments: function(){
        $('ul.nav.main ul a').each(function(i, el){
            var $el = $(el);
            // if width of link is less than container enlarge the link to fit
            if($el.width() + parseInt($el.css('padding-left'), 10) * 2 < $el.parent().width()){
                $el.width($el.parent().width() - 26);
            }
        });
    },

    loadCheckboxWarnings: function() {
        $('input[type=checkbox][data-warning]').live('click', function(){
            if ($(this).is(':not:checked')) {
                var _answer = confirm($(this).data('warning'));
                if (!_answer) {
                    $(this).attr('checked', false);
                }
            }
        });
    },

    supportsVml: function() {
        if (typeof vmlSupported == "undefined") {
            var a = document.body.appendChild(document.createElement('div'));
            a.innerHTML = '<v:shape id="vml_flag1" adj="1" />';
            var b = a.firstChild;
            b.style.behavior = "url(#default#VML)";
            vmlSupported = b ? typeof b.adj == "object": true;
            a.parentNode.removeChild(a);
        }
        return vmlSupported;
    },

    supportsSvg: function() {
        return !!document.createElementNS && !!document.createElementNS('http://www.w3.org/2000/svg', "svg").createSVGRect;
    },

    periodicallyCheckVerification: function(opts){
        var _freq = opts.frequency*1000;
        var _url = opts.url;
        var _update = opts.update;

        setInterval(function(){
            if(typeof _update === "function"){
                _update();
            }
            else{
                $(_update).load(_url);
            }
        }, _freq);
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

    hideWhenGraphsAreAvailable: function(selector) {
      if (owums.supportsSvg() || owums.supportsVml()) {
          $(document).ready(function(){
                $(selector).hide();
            });
      }
    },

    // Change verification methods on signup
    toggleVerificationMethod: function() {
        var verification_method = $('#account_verification_method').length ? $('#account_verification_method') : $('#user_verification_method');
        verification_method.change(function(){
            var val = verification_method.val(),
                mobile_phone_elements = $('#verify-mobile-phone, li.verification-block.mobile-phone'),
                credit_card_elements = $('#verify-credit-card'),
                registration_form = $('#registration-second-step').length ? $('#registration-second-step') : $('#mobile-registration li:not(.ignore-toggle)'),
                social_network_elements = $('#registration-social-network');
            if(val == 'gestpay_credit_card'){
                mobile_phone_elements.hide();
                social_network_elements.hide();
                credit_card_elements.show();
                registration_form.fadeIn(250);
            }
            else if(val == 'mobile_phone'){
                mobile_phone_elements.show();
                registration_form.fadeIn(250);
                credit_card_elements.hide();
                social_network_elements.hide();
            }
            else if(val == 'social_network'){
                mobile_phone_elements.hide();
                credit_card_elements.hide();
                registration_form.hide();
                social_network_elements.fadeIn(250);
            }
            else{
                mobile_phone_elements.hide();
                credit_card_elements.hide();
                social_network_elements.hide();
                registration_form.fadeOut(250);
            }
            owums.toggleReadonlyUsername();
        });
        // trigger once on page load
        verification_method.trigger('change');
    },

    initRegistration: function(){
        if($('#new_account').length){
            owums.toggleVerificationMethod();
            owums.initMobile2Username();
            owums.enhanceRegistration();
        }
    },

    initUserForm: function(){
        var id_document = $('#identity-document');
        if(id_document.length){
            var verification_method = $('#user_verification_method');
            verification_method.change(function(){
                if(verification_method.val() != 'identity_document'){
                    id_document.hide();
                }
                else{
                    id_document.show();
                }
            });
            // trigger once on page load
            verification_method.trigger('change');
        }
    },

    enhanceRegistration: function(){
        if(!owums.enhance_registration_form){
            return;
        }

        var mobile_confirmation = $('#confirm_mobile_phone_number'),
            email_confirmation = $('#account_email_confirmation'),
            password_confirmation = $('#account_password_confirmation'),
            mobile_suffix = $('#account_mobile_suffix'),
            email = $('#account_email'),
            password = $('#account_password'),
            is_mobile = $('#mobile-registration').length || false,
            is_error = $('#errorExplanation').length || false;

        if(is_mobile){
            email_confirmation = email_confirmation.parent().parent();
            password_confirmation = password_confirmation.parent().parent();
        }
        else{
            email_confirmation = email_confirmation.parent();
            password_confirmation = password_confirmation.parent();
        }

        if(!is_error){
            mobile_confirmation.hide();
            email_confirmation.hide();
            password_confirmation.hide();

            mobile_suffix.focusin(function(e){
                if(!mobile_confirmation.is(':visible')){
                    mobile_confirmation.slideToggle(250);
                }
            });
            if(mobile_suffix.val()!=''){
                mobile_confirmation.show();
            }

            email.focusin(function(e){
                if(!email_confirmation.is(':visible')){
                    email_confirmation.slideToggle(250);
                }
            });
            if(email.val()!=''){
                email_confirmation.show();
            }

            password.focusin(function(e){
                if(!password_confirmation.is(':visible')){
                    password_confirmation.slideToggle(250);
                }
            });
            if(password.val()!=''){
                password_confirmation.show();
            }
        }
        // fix for mobile interface
        else{
            $('#account_email_confirmation, #account_password_confirmation').parent().parent().show();
        }

        $('#account_email, #account_email_confirmation, #account_password, #account_password_confirmation').bind('contextmenu cut copy paste', function(e){
            e.preventDefault();
        });

        // prevent duplicate requests
        $('#new_account').bind('submit', function(e){
            // if form already submitted do not resubmit
            if ($('#mask').length) {
                e.preventDefault();
                return;
            }
            // show loading mask and overlay
            $('body').append('<div id="mask"></div><div id="loading-overlay"></div>');
            $('#mask').css('opacity','0').show().fadeTo(250, 0.5);
            $('#loading-overlay').togglePop();
        });
    },

    initMobile2Username: function(){
        if(owums.use_mobile_phone_as_username){
            var username = $('#account_username'),
                prefix = $('#account_mobile_prefix'),
                suffix = $('#account_mobile_suffix');
            var updateUsername = function(){
                username.val(prefix.val()+suffix.val());
            }
            $('#account_mobile_prefix, #account_mobile_prefix_confirmation')
            .bind('focusin focusout change', function(e){
                updateUsername();
            });
            $('#account_mobile_suffix, #account_mobile_suffix_confirmation, #account_given_name')
            .bind('keyup focusin focusout', function(e){
                updateUsername();
            });
        }
    },

    toggleReadonlyUsername: function(){
        if(owums.use_mobile_phone_as_username){
            var username = $('#account_username');
            if($('#account_verification_method').val() == 'mobile_phone'){
                username.attr('readonly', 'readonly').addClass('readonly');
                if(owums.use_mobile_phone_as_username_hidden){
                    username.parent().hide();
                }
            }
            else{
                username.removeAttr('readonly').removeClass('readonly');
                if(owums.use_mobile_phone_as_username_hidden){
                    username.parent().show();
                }
            }
        }
    },

    toggleOverlay: function(closeCallback){
        var mask = $('#mask'),
            close = $('.close'),
            overlay = $('.overlay');

        var closeOverlay = function(){
            if(close.attr('data-confirm-message') !== undefined && !window.confirm(close.attr('data-confirm-message'))){
               return false;
            }
            overlay.fadeOut();
            mask.fadeOut();
            if(closeCallback && typeof(closeCallback) === "function" ){
                closeCallback();
            }
            return true;
        }

        if(!overlay.is(':visible')){
            mask.css('opacity','0').show().fadeTo(250, 0.7);
            overlay.centerElement().fadeIn(250);
        }
        else{
            closeOverlay();
        }
        if($.data(close.get(0), 'events') === undefined){
            close.click(function(e){
                closeOverlay();
            });
        }
    },

    initCreditCardOverlay: function(){
        var bank_gateway = $('#bank-gateway');
        if(bank_gateway.length && !bank_gateway.hasClass('mobile')){
            var overlay = $('.overlay'),
                loading = $('#loading-overlay');
            loading.togglePop();
            owums.enhanceCreditCardForm();
            $(window).resize(function(e){
              overlay.centerElement();
            }).load(function(e){
                var closeCallback = function(){
                    var url = $('.close').attr('data-callback-url');
                    $('#verification').load(url);
                }
                owums.toggleOverlay(closeCallback);
            });
            loading.togglePop();
        }
        else if(bank_gateway.length && bank_gateway.hasClass('mobile')){
            owums.enhanceCreditCardFormMobile();
        }
    },

    enhanceCreditCardForm: function(){
        $('#credit_card_number input').bind('keyup', function(e){
            var $this = $(this);
            // when max length of input form is reached and a number key is pressed
            if($this.val().length == $this.attr('maxlength') &&
               ( (e.keyCode >= 48 && e.keyCode < 57) || (e.keyCode >= 96 && e.keyCode < 105) )
            ){
                var next = $this.next();
                // focus next input
                if(next.length){
                    next.focus()
                }
                // focus on select month of expiry date
                else{
                    $('#bank-gateway select').eq(0).focus()
                }
            }
        });
        // allow only numbers on credit card number and cvv fields
        $('#bank-gateway input[type=text]').keydown(function(e) {
            var $this = $(this);
            // Allow: backspace, delete, tab, escape, and enter
            if (e.keyCode == 46 || e.keyCode == 8 || e.keyCode == 9 || e.keyCode == 27 || e.keyCode == 13 ||
                 // Allow: Ctrl+A
                (e.keyCode == 65 && e.ctrlKey === true) ||
                 // Allow: home, end, left, right
                (e.keyCode >= 35 && e.keyCode <= 39)) {
                    // let it happen, don't do anything
                    return
            }
            else {
                // Ensure that it is a number and stop the keypress
                if (e.shiftKey || (e.keyCode < 48 || e.keyCode > 57) && (e.keyCode < 96 || e.keyCode > 105 )) {
                    e.preventDefault()
                }
                else{
                    // remove any error class if present
                    if($this.hasClass('error')){
                        $this.removeClass('error');
                    }
                }
            }
        });
        // on submit
        $('#bank-gateway form').submit(function(e){
            var error = false;
            $(this).find('input[type=text]').each(function(i, e){
                var input = $(e)
                if(
                   ( input.attr('name').indexOf('number') >= 0 && input.val().length < 4 ) ||
                   ( input.attr('name').indexOf('cvv') >= 0 && input.val().length < 3 )
                ){
                    input.addClass('error');
                    error = true;
                }
            });
            if(error){
                return false
            }
            else{
                owums.toggleLockOverlay();
                owums.initCreditCardLoading();
                return true
            }
        });
    },

    enhanceCreditCardFormMobile: function(){
        $('#credit_card_number input').bind('keyup', function(e){
            var $this = $(this);
            // when max length of input form is reached and a number key is pressed
            if($this.val().length == 4 &&
               ( (e.keyCode >= 48 && e.keyCode < 57) || (e.keyCode >= 96 && e.keyCode < 105) )
            ){
                var next = $this.next();
                // focus next input
                if(next.length){
                    next.focus()
                }
                // focus on select month of expiry date
                else{
                    $('select').eq(0).focus()
                }
                return true
            }
            return false;
        });
        // allow only numbers on credit card number and cvv fields
        $('form#cc_form input[type=text]').keydown(function(e) {
            var $this = $(this);
            // Allow: backspace, delete, tab, escape, and enter
            if (e.keyCode == 46 || e.keyCode == 8 || e.keyCode == 9 || e.keyCode == 27 || e.keyCode == 13 ||
                 // Allow: Ctrl+A
                (e.keyCode == 65 && e.ctrlKey === true) ||
                 // Allow: home, end, left, right
                (e.keyCode >= 35 && e.keyCode <= 39)) {
                    // let it happen, don't do anything
                    return
            }
            else {
                // Ensure that it is a number and stop the keypress
                if (e.shiftKey || (e.keyCode < 48 || e.keyCode > 57) && (e.keyCode < 96 || e.keyCode > 105 )) {
                    e.preventDefault()
                }
                else{
                    // remove any error class if present
                    if($this.hasClass('error')){
                        $this.removeClass('error');
                    }
                }
            }
        });
        $('form#cc_form').submit(function(e){
            var error = false;
            $(this).find('input[type=text]').each(function(i, e){
                var input = $(e)
                if(
                   ( input.attr('name').indexOf('number') >= 0 && input.val().length < 4 ) ||
                   ( input.attr('name').indexOf('cvv') >= 0 && input.val().length < 3 )
                ){
                    input.addClass('error');
                    error = true;
                }
            });
            if(error){
                return false
            }
            else{
                if(!$('#mask').length){
                    $('#verification').after('<div id="mask"></div><div id="loading-overlay"></div><div id="loading-message"></div>');
                }
                $('#mask').css('opacity','0').show().fadeTo(250, 0.5);
                owums.initCreditCardLoading();
                return true
            }
        });
    },

    toggleLockOverlay: function(){
        var mask = $('#mask'),
            z = 10,
            o = 0.7;
        if(mask.css('z-index') < 20){
            z = 99;
            o = 0.5;
        }
        mask.css({
            zIndex: z,
            opacity: o
        });
    },

    initCreditCardLoading: function(){
        $('#loading-overlay').togglePop();
        owums.timeouts = [];
        owums.timeouts[0] = setTimeout(function(){
            $('#loading-message').toggleMessage(i18n.verification_message_first_step);
        }, 1500);
        owums.timeouts[1] = setTimeout(function(){
            $('#loading-message').html(i18n.verification_message_second_step);
        }, 4000);
    },

    clearTimeouts: function(){
        if(owums.timeouts){
            for(i in owums.timeouts){
                clearTimeout(owums.timeouts[i]);
            }
        }
    },

    initNotice: function(){
        $('#notice .close').click(function(e){
            e.preventDefault();
            $(this).parent().parent().fadeToggle(400);
        });
    },

    ajaxQuickSearch: function() {
        var inputField = $(this.quickSearchDiv).find('input[type=text]');
        inputField.observe(function() {
            $(owums.loadingDiv).fadeIn();
            inputField.parent('form').submit();
            $(owums.loadingDiv).ajaxStop(function(){$(this).fadeOut();});
        }, 1);
    },

    ajaxLoading: function() {
        $('[data-remote=true]').live('click', function(){
            $(owums.loadingDiv).fadeIn().ajaxStop(function(){
                $(owums.loadingDiv).fadeOut();
            });
        });
    },

    path: function(path) {
        var _curr = window.location.pathname,
            _params = window.location.search,
            // added for backward compatibility
            _subUri = (owums.subUri === '' && _curr.indexOf('/owums/') === 0) ? 'owums' : owums.subUri;
        if (path.charAt(0) === '/') {
            if (_curr.substr(1, _subUri.length) === _subUri) {
                var _prefix = _subUri ? '/'+_subUri : '';
                return _prefix+path+_params;
            } else {
                return path+_params;
            }
        } else {
            return _curr+'/'+path+_params;
        }
    },

    initSelectable: function(){
        $('#operator_roles').customSelectable();
        $("#radius_groups-table").customSelectable();
    }
};

$.fn.customSelectable = function(options){
    var opts = $.extend({
        'init': null,
        'beforeSelect': null,
        'afterSelect': null
    }, options);
    var table = $(this);
    table.addClass('selectable');
    if(opts.init){ opts.init.apply(table) }
    table.find('tbody tr').click(function(e){
        if(opts.beforeSelect){ opts.beforeSelect.apply($(this)) }
        el = $(this);
        var checkbox = el.find('input[type=checkbox]');
        checkbox.attr('checked', !checkbox.attr('checked'))
        el.toggleClass('selected');
        if(opts.afterSelect){ opts.afterSelect.apply($(this)) }
    });

    table.find('input[checked=checked]').parents('tr').addClass('selected');

    return table;
}
