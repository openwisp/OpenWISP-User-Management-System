$.getJSON('stats/traffic', function(traffic){
    graphs.init({
        chart: {
            renderTo: 'traffic',
            type: 'column',
            height: 250,
            zoomType: 'xy'
        },
        title: { text: null },
        credits: { enabled: false },
        legend: { borderWidth: 0 },
        colors: ['#8AD96D', '#913FA6', '#BF2424'],
        plotOptions: {
            column: { stacking: 'normal' },
            series: {
                marker: {
                    fillColor: '#FFFFFF',
                    lineWidth: 2,
                    lineColor: null
                }
            }
        },
        xAxis: {
            gridLineWidth: 1,
            tickLength: 2,
            type: 'datetime'
        },
        yAxis: {
            title: { text: null },
            labels: {
                formatter: function() { return graphs.bytes_formatter(this.value, true); }
            }
        },
        tooltip: {
            formatter: function() {
                return '<strong>'+ Highcharts.dateFormat('%a %e %b %Y', this.x) +'</strong><br/>'+ graphs.bytes_formatter(this.y, true);
            }
        },
        series: traffic
    });
});