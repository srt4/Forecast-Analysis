function drawChart() {
    var data = google.visualization.arrayToDataTable([
        ['Day', 'Temp']
            }
?>
            ]);

            var options = {
                title: 'GFS Highs',
                hAxis: {title: 'Day',  titleTextStyle: {color: 'red'}}
            };

            var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));
            chart.draw(data, options);
        }