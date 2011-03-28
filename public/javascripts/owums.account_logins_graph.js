$.getJSON('stats/account_logins', function(logins){
    graphs.init({
        chart: {
            renderTo: 'account_logins_graph',
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
                formatter: function() { return graphs.time_formatter(this.value); }
            }
        },
        tooltip: {
            formatter: function() {
                return graphs.time_formatter(this.y);
            }
        },
        series: logins
    });
});

