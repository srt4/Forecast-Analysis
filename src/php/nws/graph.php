<script type="text/javascript" src="https://www.google.com/jsapi"></script>
<script src="http://code.jquery.com/jquery-1.8.3.min.js"></script>
<?php require('getter.php'); ?>
<script type="text/javascript">
    google.load("visualization", "1", {packages:["corechart"]});
    google.setOnLoadCallback(drawChart);
    function drawChart() {
        var data = new google.visualization.DataTable();
        data.addColumn("number", "day");
        data.addColumn("number", "high temp");
        data.addColumn("number", "days out");
        data.addRows([<?php
            $i = 0;
    foreach($json as $forecast) {
?>
       [{v: <?=$i++?>, f: '<?=$forecast['pd']?>'}, <?=$forecast['high']?>, <?=$forecast['delta']?>],
        <?php
    }
?>] );

        var formatter = new google.visualization.ColorFormat();
        formatter.addGradientRange(0, 10, "white", "blue", "white");
        formatter.format(data, 1); // Apply formatter to second column

        var options = {
            title: 'Weather',
            hAxis: {title: 'Day', minValue: 0, maxValue: 15},
            vAxis: {title: 'Temp', minValue: 20, maxValue: 90},
            legend: 'none'
        };

        var chart = new google.visualization.ScatterChart(document.getElementById('chart_div'));
        chart.draw(data, options);
    }


</script>
<!--<div id="chart_div" style="width: 900px; height: 500px;"></div>-->


<script src="http://code.highcharts.com/highcharts.js"></script>
<script src="http://code.highcharts.com/modules/exporting.js"></script>

    <script>
        var series = [];
        var sidewaysData = <?=json_encode($newjson)?>;
        var dayMap = <?=json_encode($dates)?>;
        $.each(sidewaysData, function(key, obj) {
            console.log(obj); // arr
            console.log(key); // 0
            var tempArray = [];

            $.each(obj, function(k, v) {
               tempArray.push([
                    new Date(v.pd).getTime(),
                    parseInt(v.high)
               ]);
            });

            series.push(
                {
                    type:'scatter',
                    name: key + " days in advance",
                    data: tempArray,
                    marker: {
                        radius: 4,
                        fillColor: (function() {
                            return "rgb(" + (0 + (key * 30)) + ", " + (0 + (key * 15)) + ", " + (0 + (key * 15)) +")";
                        })()
                    }
                }
            )
        });

        $(function () {
            var chart;
            $(document).ready(function() {
                chart = new Highcharts.Chart({
                    chart: {
                        renderTo: 'container'
                    },
                    xAxis: {
                        type: 'datetime'
                    },
                    yAxis: {
                        min: 20,
                        max: 90
                    },
                    title: {
                        text: 'Scatter plot with regression line'
                    },
                    series: series
                });
            });

        });
    </script>
<div id="container" style="min-width: 400px; height: 400px; margin: 0 auto"></div>
​
