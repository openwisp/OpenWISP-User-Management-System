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
                maxDate: graphs.today(),
                defaultDate: "+1w",
                showButtonPanel: true,
                changeMonth: true,
                onSelect: function(selectedDate) {
                    var option = this.id == "from" ? "minDate" : "maxDate",
                            instance = $(this).data("datepicker"),
                            date = $.datepicker.parseDate(instance.settings.dateFormat, selectedDate, instance.settings);
                    dates.not(this).datepicker("option", option, date);
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

