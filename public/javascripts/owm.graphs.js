var graphs = {
    locales: [
        {
            locale: 'it',
            triggerIfExists: '.current_it',
            lang: {
                resetZoom: 'Reimposta Zoom',
                months: ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto',
                    'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
                weekdays: ['Domenica', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato']
            }
        },
        {
            locale: 'en',
            triggerIfExists: '.current_en',
            lang: {resetZoom: 'Reset Zoom'}
        }
    ],

    // Private functions and variables
    _plotted: [],
    init: function(_graph) {
        $(document).ready(function() {
            graphs.setLocale();
            graphs._plotted.push(new Highcharts.Chart(_graph));
        });
    },

    setLocale: function() {
        $.each(graphs.locales, function(){
            if (owm.exists(this.triggerIfExists)) {
                Highcharts.setOptions({lang: this.lang});
            }
        });
    },

    daysAgo: function(days) {
        return new Date().setDate(graphs.today().getDate()-days);
    },

    today: function() {
        return new Date();
    },

    bytes_formatter: function(bytes, label) {
        if (bytes == 0) return '';
        var s = ['bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
        var e = Math.floor(Math.log(bytes)/Math.log(1024));
        var value = ((bytes/Math.pow(1024, Math.floor(e))).toFixed(2));
        e = (e<0) ? (-e) : e;
        if (label) value += ' ' + s[e];
        return value;
    }
};

