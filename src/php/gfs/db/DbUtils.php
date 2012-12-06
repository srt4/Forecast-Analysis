<?php
class DBUtils {
    public static function initDb() {
        require_once('../lib/meekrodb.php');
        DB::$dbName = "gfsforecasts";
        DB::$user = "root";
        DB::$password = "toor";
    }
}