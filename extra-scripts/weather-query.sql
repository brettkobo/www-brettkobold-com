sql <- glue("#standardSQL
WITH params AS (
  SELECT ST_GeogPoint({lat},{lon}) AS center,
         50 AS maxn_stations,
         50 AS maxdist_km
),

distance_from_center AS (
  SELECT
    id,
    name,
    state,
    ST_GeogPoint(longitude, latitude) AS loc,
    ST_Distance(ST_GeogPoint(longitude, latitude), params.center) AS dist_meters
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_stations`,
    params
  WHERE ST_DWithin(ST_GeogPoint(longitude, latitude), params.center, params.maxdist_km*1000)
),

nearest_stations AS (
  SELECT 
    *, 
    RANK() OVER (ORDER BY dist_meters ASC) AS rank
  FROM 
    distance_from_center
),

nearest_nstations AS (
  SELECT 
    station.* 
  FROM 
    nearest_stations AS station, params
  WHERE 
    rank <= params.maxn_stations
),

wxobs AS (
  SELECT
    wx.date AS date,
    IF (wx.element = 'PRCP', wx.value/10, NULL) AS prcp,
    IF (wx.element = 'TMIN', wx.value/10, NULL) AS tmin,
    IF (wx.element = 'TMAX', wx.value/10, NULL) AS tmax,
    station.id AS id, 
    station.name AS name, 
    station.dist_meters AS dist
  FROM
    `bigquery-public-data.ghcn_d.ghcnd_2018` AS wx
  JOIN nearest_nstations AS station ON wx.id = station.id
  WHERE
    DATE_DIFF(CURRENT_DATE(), wx.date, DAY) < 30
),

daily_wx AS (
  SELECT
    date,
    MAX(prcp) AS prcp,
    MAX(tmin) AS tmin,
    MAX(tmax) AS tmax,
    id,
    MAX(name) AS name,
    MAX(dist) AS dist
  FROM 
    wxobs
  GROUP BY
    date, id
  ORDER BY
    date ASC
)

SELECT 
  date,
  MAX((tmin*(9/5))+31) AS min,
  MAX((tmax*(9/5))+31) AS max,
  MAX(prcp) as rain
FROM 
  daily_wx
GROUP BY date
ORDER BY date desc")