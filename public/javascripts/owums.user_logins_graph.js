$.getJSON(owums.path('stats/user_logins.json'), function(logins){
    graphs.init({
        chart: {
            renderTo: 'user_logins_graph',
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
                formatter: function() { return graphs.time_formatter(this.value); }
            }
        },
        tooltip: {
            formatter: function() {
                return '<span style="font-size:10px">'+Highcharts.dateFormat('%A, %b %e, %Y', this.x)+'<br/><strong>'+graphs.time_formatter(this.y)+'</strong></span>';
            }
        },
        series: logins
    });
});
