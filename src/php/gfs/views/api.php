<?php
require('../db/DbUtils.php');

function getColumnForModel($model, $column) {
    DBUtils::initDb();
    $result = DB::query("SELECT ValidTime, $column FROM Forecasts WHERE time = '$model' ORDER BY ValidTime ASC");
    $data = array();
    $column = explode(",", $column);
    foreach($result as $datum) {
        $data[$datum["ValidTime"]] = array();
        foreach($column as $c) {
            $data[$datum["ValidTime"]][$c] = $datum[$c];
        }
    }
    return $data;
}

function getColumnForModels($model, $column) {
    DBUtils::initDb();
    $model = explode(",", $model);
    $result = DB::query("SELECT ValidTime, $column FROM Forecasts WHERE time in %ls", $model);

}

$model = $_REQUEST['model'];
$column = $_REQUEST['column'];

echo json_encode(getColumnForModel($model, $column));