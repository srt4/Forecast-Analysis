<?php require("../db/SimpleGetter.php"); ?>
<html>
<head>
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
        google.load("visualization", "1", {packages:["corechart"]});
        google.setOnLoadCallback(drawChart);
        function drawChart() {
            var data = google.visualization.arrayToDataTable([
                ['Day', 'Temp'] <?php
            foreach($rows as $row) {
?>
                ,["<?=$row["ValidTime"]?>", <?=$row["MaxTemp__F"]?>]
                <?php
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
    </script>
</head>
<body>
<div id="chart_div" style="width: 900px; height: 500px;"></div>
</body>
</html>