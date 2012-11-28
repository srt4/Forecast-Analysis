<?php
$forecastTenDay = json_decode(file_get_contents("http://api.wunderground.com/api/71bf9296163c4749/forecast10day/q/WA/Seattle.json"));

echo "<pre>";

$forecasts = $forecastTenDay->forecast->simpleforecast->forecastday;
//print_r($forecasts);

$link = mysql_connect("localhost", "root", "toor");
mysql_select_db("forecast");


foreach($forecasts as $forecast) {
    $day = $forecast->date->epoch;
    $high = $forecast->high->fahrenheit;
    $low = $forecast->low->fahrenheit;

    $query = "INSERT INTO forecasts VALUES(1, CURRENT_DATE, FROM_UNIXTIME($day), $low, $high)";
    $res = mysql_query($query);
    if (!$res) {
        //echo mysql_error();
    }
}

$result = mysql_query("SELECT *, DATEDIFF(pdate, fdate) as delta  FROM forecasts ORDER BY fdate ASC");

$json = array();
while ($row = mysql_fetch_object($result)) {
    $json[] = array(
        "delta" => $row->delta,
        "fd" => $row->fdate,
        "pd" => $row->pdate,
        "high" => $row->high
    );
}

$newjson = array();

foreach($json as $forecast) {
    if (!isset($newjson[$forecast['delta']])) {
        $newjson[$forecast['delta']] = array();
    }
    $newjson[$forecast['delta']][] = $forecast;
}

$result = mysql_query("SELECT DISTINCT pdate FROM forecasts ORDER BY pdate ASC");
$dates = array();
$i = 0;
while ($row = mysql_fetch_object($result)) {
    $dates[$row->pdate] = $i++;
}
