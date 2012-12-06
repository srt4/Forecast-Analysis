<?php
class ForecastCollection
{
    private $forecastArray;

    public function __construct() {
        $forecastArray = array();
    }

    public function getForecast($timestamp) {
        if (isset($forecastArray))
    }

    public function addForecast(Forecast $forecast) {
        $forecastArray[] = $forecast;
    }
}