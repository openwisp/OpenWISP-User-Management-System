var graphs = {
    locales: [
        {
            locale: 'it',
            triggerIfExists: '.current_it',
            lang: {
                resetZoom: 'Reimposta Zoom',
                months: ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto',
                    'Settembre', 'Ottobre', 'Novembre', 'Dicembre'],
                weekdays: ['Domenica', 'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato'],
                downloadPNG: 'Esporta immagine PNG',
                downloadJPEG: 'Esporta immagine JPEG',
                downloadPDF: 'Esporta documento PDF',
                downloadSVG: 'Esporta immagine vettoriale SVG'
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
            if (owums.exists(this.triggerIfExists)) {
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

