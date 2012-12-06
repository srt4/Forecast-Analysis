<script src="../js/jquery.js"></script>
    <link rel="stylesheet" type="text/css" href="../css/models.css" />
<?php
require('../db/DbUtils.php');
DBUtils::initDb();

$models = DB::queryFirstColumn("SELECT DISTINCT(time) FROM Forecasts");
$columnSet = DB::queryFirstRow("SELECT * FROM Forecasts");
$columns = array();
$columnBlacklist = array("time", "ValidTime");
foreach($columnSet as $name => $column) {
    if (in_array($name, $columnBlacklist))
        continue;
    $columns[] = $name;
}
?>
<script type="text/javascript">
    var model;
    var variable;
    $(document).ready(function() {
        $("a").click(function() {
            if ($(this).parent().hasClass("top")) {
                $("div.top a").removeClass("selected");
                $(this).addClass("selected");
            } else {
                $(this).toggleClass("selected");
            }
            updateGraph();
        });

        function updateGraph() {
            var models = [];
            var variables = [];

            $("#models a.selected").each(function(key, model) {
                models.push($(model).attr("id"));
            });

            $(".left a.selected").each(function(key, variable) {
                variables.push($(variable).attr("id"));
            });

            if (models.length > 0 && variables.length > 0) {
                $.getJSON("api.php", {
                    model: models.join(""),
                    column: variables.join(",")
                }, function(response) {
                    var finalData = [];
                    var graphData = ["ValidTime"];
                    $.each(variables, function(key, value) {
                        graphData.push(value);
                    });
                    finalData.push(graphData);
                    $.each(response, function(key,value) {
                        var line = [key.substring(5, key.length)];
                        $.each(value, function(k,v){
                            var floatValue = parseFloat(v, 10);
                            if(!floatValue) {
                                console.log(v.trim() + ".");
                                floatValue = parseFloat(v.trim().split(" ")[1], 10);
                            }
                            line.push(floatValue);
                        });
                        finalData.push(line);
                    });
                    drawChart(finalData);
                });
            }
        }
    });
</script>
<div id="models" class="top">
    <?php
    foreach($models as $model) {
        ?>
        <a id="<?=$model?>" href="#"><?=$model?></a>
    <?php
    }
?>
</div>

<div class="left">
    <?php
    foreach($columns as $column) {
    ?>
        <a id="<?=$column?>"><?=$column?></a>
        <?php
    }
?>
</div>
<div class="right">
    <script type="text/javascript" src="https://www.google.com/jsapi"></script>
    <script type="text/javascript">
        google.load("visualization", "1", {packages:["corechart"]});
        function drawChart(data) {
            var data = google.visualization.arrayToDataTable(data);

            var hAxis = {title:'Day', titleTextStyle: {color: 'red'}};
            var vAxis = {};
            console.log($("#ymin").val());
            if ($("#ymin").val() != "ymin" && $("#ymax").val() != "ymax") {
                vAxis.maxValue = parseInt($("#ymax").val(), 10);
                vAxis.minValue = parseInt($("#ymin").val(), 10);
            }
            console.log(hAxis);
            var options = {
                title: 'Source: GFS',
                hAxis: hAxis,
                vAxis: vAxis
            };

            var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));
            chart.draw(data, options);
        }
    </script>
    <input type="text" value="ymin" onclick="this.value = ''" id="ymin" />
    <input type="text" value="ymax" onclick="this.value = ''" id="ymax" />

    <div id="chart_div" style="margin-left:25%; width: 900px; height: 500px;"></div>

</div>
