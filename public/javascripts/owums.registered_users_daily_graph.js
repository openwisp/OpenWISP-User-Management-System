/*
# This file is part of the OpenWISP User Management System
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

$.getJSON(owums.path('/stats/registered_users_daily.json'), function(registered_users){
    graphs.init({
        chart: {
            renderTo: 'registered_users_daily_graph',
            zoomType: 'x'
        },
        title: { text: null },
        credits: { enabled: false },
        legend: { borderWidth: 0 },
        colors: ['#BF2424', '#5ad900', '#1a32ea'],
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
            maxZoom: 7 * 24 * 3600000,
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
