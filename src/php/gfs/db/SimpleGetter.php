<pre>
<?php
require("../lib/meekrodb.php");
{
    DB::$user = 'root';
    DB::$password = 'toor';
    DB::$dbName = 'gfsforecasts';
}


$rows = DB::query("SELECT * FROM Forecasts WHERE time = (SELECT MAX(time) FROM Forecasts)");
foreach($rows as $row) {
    //print_r($row);
}
