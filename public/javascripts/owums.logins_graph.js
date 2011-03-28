$.getJSON('stats/logins', function(logins){
    graphs.init({
        chart: {
            renderTo: 'logins_graph',
            type: 'column',
            zoomType: 'xy'
        },
        title: { text: null },
        credits: { enabled: false },
        legend: { borderWidth: 0 },
        colors: ['#478EDD', '#FF9431'],
        plotOptions: {
            column: { stacking: 'normal' }
        },
        xAxis: {
            gridLineWidth: 1,
            tickLength: 2,
            type: 'datetime'
        },
        yAxis: {
            title: { text: null }
        },
        tooltip: {
            formatter: function() {
                return '<strong>'+ Highcharts.dateFormat('%a %e %b %Y', this.x) +'</strong><br/>'+ this.y;
            }
        },
        series: logins
    });
});