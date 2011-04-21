$.getJSON(owums.path('/stats/traffic.json'), function(traffic){
    graphs.init({
        chart: {
            renderTo: 'traffic_graph',
            type: 'column',
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
            type: 'datetime',
            labels: {step:2}
        },
        yAxis: {
            title: { text: null },
            labels: {
                formatter: function() { return graphs.bytes_formatter(this.value, true); }
            }
        },
        tooltip: {
            formatter: function() {
                var dateStr = Highcharts.dateFormat('%A, %b %e, %Y', this.x);
                var nameStr = '<span style="color:'+this.series.color+'">'+this.series.name+'</span>';
                var valStr = '<strong>'+graphs.bytes_formatter(this.y, true)+'</strong>';
                return '<span style="font-size:10px">'+dateStr+'<br/>'+nameStr+'<span style="color:black">: </span>'+valStr+'</span>';
            }
        },
        exporting: {
            url: owums.path('/stats/export'),
            width: 1200,
            buttons: {
                printButton: {enabled: false},
                exportButton: {verticalAlign: 'bottom', y:-5}
            }
        },
        series: traffic
    });
});
