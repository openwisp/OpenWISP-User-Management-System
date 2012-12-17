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
    owums.initRegistration();
});

$.fn.resizeElement = function(padding){
    padding = padding || 60;
    var el = $(this);  
    el.height($(window).height()-padding)
    .width($(window).width()-padding);
    return el;
}
$.fn.centerElement = function(){
    var el = $(this);
    el.css('top', ($(window).height() - el.height()) / 2)
    .css('left', ($(window).width() - el.width()) / 2);
    return el;
}
$.fn.togglePop = function(speed){
    speed = speed || 150;
    el = $(this);
    el.centerElement();
    (el.is(':visible')) ? el.fadeOut(speed) : el.fadeIn(speed);
    return el;
}

var owums = {
    subUri: 'owums',
    quickSearchDiv: '#quicksearch',
    loadingDiv: '#loading',

    exists: function(selector) {
        return ($(selector).length > 0);
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
            $(_update).load(_url);
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

    //Change verification methods on signup
    toggleVerificationMethod: function() {
        var verification_method = $('#account_verification_method');
        verification_method.change(function(){
            if(verification_method.val() != 'mobile_phone'){
                $('#verify-mobile-phone').hide();
                $('#verify-credit-card').show();
            }
            else{
                $('#verify-mobile-phone').show();
                $('#verify-credit-card').hide();
            }
            owums.toggleReadonlyUsername();
        });
        // trigger once on page load
        verification_method.trigger('change');
    },
    
    initRegistration: function(){
        if($('#registration').length){
            this.toggleVerificationMethod();
            this.initCreditCardOverlay();
            this.initMobile2Username();
        }
    },
    
    initMobile2Username: function(){
        if(owums.use_mobile_phone_as_username){
            var username = $('#account_username'),
                prefix = $('#account_mobile_prefix'),
                suffix = $('#account_mobile_suffix');
            var updateUsername = function(){
                username.val(prefix.val()+suffix.val());
            }
            suffix.bind('keyup', function(e){
                updateUsername();
            });
            prefix.change(function(e){
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
            overlay.resizeElement().centerElement().fadeIn(250);
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
        if($('#bank-gateway').length){
            var overlay = $('.overlay'),
            loading = $('#loading-overlay');
            
            loading.togglePop();    
            
            $(window).resize(function(e){
              overlay.resizeElement().centerElement();
            }).load(function(e){
                var closeCallback = function(){
                    var url = $('.close').attr('data-callback-url');
                    $('#verification').load(url);
                }
                owums.toggleOverlay(closeCallback);
            });
            $('iframe').one('load', function(){
              loading.togglePop();
            });    
        }
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

