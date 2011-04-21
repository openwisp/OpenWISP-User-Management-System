$.getJSON(owums.path('/stats/registered_users.json'), function(registered_users){
    graphs.init({
        chart: {
            renderTo: 'registered_users_graph',
            zoomType: 'x'
        },
        title: { text: null },
        credits: { enabled: false },
        legend: { borderWidth: 0 },
        colors: ['#BF2424'],
        plotOptions: {
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
            minPadding: 0.03,
            maxPadding: 0.03,
            tickLength: 2,
            type: 'datetime'
        },
        yAxis: {
            title: { text: null },
            allowDecimals: false
        },
        exporting: {
            url: owums.path('/stats/export'),
            width: 1200,
            buttons: {
                printButton: {enabled: false},
                exportButton: {verticalAlign: 'bottom', y:-5}
            }
        },
        series: registered_users
    });
});
