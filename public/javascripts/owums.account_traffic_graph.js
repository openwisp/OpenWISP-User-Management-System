$.getJSON(owums.path('/stats/account_traffic.json'), function(traffic){
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
            type: 'datetime',
            minPadding: 0.05,
            maxPadding: 0.05
        },
        yAxis: {
            title: { text: null },
            labels: {
                formatter: function() { return graphs.bytes_formatter(this.value, true); }
            }
        },
        tooltip: {
            formatter: function() {
                return '<span style="font-size:10px">'+Highcharts.dateFormat('%A, %b %e, %Y', this.x)+'<br/><strong>'+graphs.bytes_formatter(this.y, true)+'</strong></span>';
            }
        },
        series: traffic
    });
});
