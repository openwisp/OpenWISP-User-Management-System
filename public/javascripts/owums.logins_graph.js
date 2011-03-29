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
            type: 'datetime',
            labels: {step:2}
        },
        yAxis: {
            title: { text: null }
        },
        series: logins
    });
});
