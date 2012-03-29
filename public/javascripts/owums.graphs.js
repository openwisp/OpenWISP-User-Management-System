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

var graphs = {
    locales: [
        {
            locale: 'it',
            triggerIfExists: '.current_it',
            lang: {
                // Highcharts specific
                resetZoom: 'Reimposta Zoom',
                months: ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto',
                    'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
                weekdays: ['Domenica', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato'],
                downloadPNG: 'Esporta immagine PNG',
                downloadPDF: 'Esporta documento PDF',
                downloadSVG: 'Esporta immagine vettoriale SVG',
                // jQueryUI datepicker specific
                dateFormat: 'dd/mm/yy',
                firstDay: 1,
                closeText: 'Chiudi',
                prevText: '&#x3c;Prec',
                nextText: 'Succ&#x3e;',
                currentText: 'Oggi',
                monthsShort: ['Gen','Feb','Mar','Apr','Mag','Giu','Lug','Ago','Set','Ott','Nov','Dic'],
                weekdaysShort: ['Dom','Lun','Mar','Mer','Gio','Ven','Sab'],
                weekdaysMin: ['Do','Lu','Ma','Me','Gi','Ve','Sa']
            }
        },
        {
            locale: 'en',
            triggerIfExists: '.current_en',
            lang: {
                // Highcharts specific
                resetZoom: 'Reset Zoom'
            }
        }
    ],

    // Private functions and variables
    _plotted: [],
    init: function(_graph) {
        $(document).ready(function() {
            graphs.dateRangePicker();
            graphs.setLocale();
            graphs._plotted.push(new Highcharts.Chart(_graph));
        });
    },

    setLocale: function() {
        $.each(graphs.locales, function(){
            if (owums.exists(this.triggerIfExists)) {
                var _lang = this.lang;
                Highcharts.setOptions({lang: _lang});
                // Load localization for datepicker if enabled
                if ($.datepicker != undefined && this.locale !== 'en') {
                    $.datepicker.setDefaults({
                        firstDay: _lang.firstDay, monthNames: _lang.months,
                        monthNamesShort: _lang.monthsShort, dayNames: _lang.weekdays,
                        dayNamesShort: _lang.weekdaysShort, dayNamesMin: _lang.weekdaysMin,
                        closeText: _lang.closeText, prevText: _lang.prevText,
                        nextText: _lang.nextText, currentText: _lang.currentText,
                        dateFormat: _lang.dateFormat
                    });
                }
            }
        });
    },

    dateRangePicker: function(){
        if (owums.exists('#from') && owums.exists('#to')) {
            var dates = $( "#from, #to" ).datepicker({
                minDate: '-10y',
                maxDate: graphs.today(),
                defaultDate: "+1w",
                showButtonPanel: true,
                changeMonth: true,
                changeYear: true,
                yearRange: 'c-10:',
                onSelect: function( selectedDate ) {
                    var option = this.id == "from" ? "minDate" : "maxDate",
                            instance = $( this ).data( "datepicker" ),
                            date = $.datepicker.parseDate(
                                    instance.settings.dateFormat || $.datepicker._defaults.dateFormat,
                                    selectedDate, instance.settings
                            );
                    dates.not( this ).datepicker( "option", option, date );
                }
            });
        }
    },

    daysAgo: function(days) {
        return new Date().setDate(graphs.today().getDate()-days);
    },

    today: function() {
        return new Date();
    },

    bytes_formatter: function(bytes, label) {
        bytes = Math.floor(bytes);
        if (bytes == 0) return '0 B';
        var s = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
        var e = Math.floor(Math.log(bytes)/Math.log(1024));
        var value = ((bytes/Math.pow(1024, Math.floor(e))).toFixed(2));
        e = (e<0) ? (-e) : e;
        if (label) value += ' ' + s[e];
        return value;
    },

    time_formatter: function(value) {
        var h=Math.floor(value/3600);
        var m=Math.floor(value/60)-(h*60);
        var s=Math.floor(value-(h*3600)-(m*60));

        var hours = (h < 10 ? '0' : '') + h;
        var minutes = (m < 10 ? '0' : '') + m;
        var seconds = (s < 10 ? '0' : '') + s;

        return hours+':'+minutes+':'+seconds;
    }
};

