$.getJSON('stats/account_traffic', function(traffic){
    graphs.init({
        chart: {
            renderTo: 'account_traffic_graph',
            type: 'column'
        },
        title: { text: null },
        credits: { enabled: false },
        legend: { borderWidth: 0 },
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