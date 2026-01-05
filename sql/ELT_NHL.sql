-- Nastavenie správnej databázy a warehousu a tvorba schémy
USE WAREHOUSE TAPIR_WH;
USE DATABASE TAPIR_DB;
CREATE OR REPLACE SCHEMA TAPIR_DB.projekt;
USE SCHEMA projekt;

-- Načítanie údajov do staging tabuľky
CREATE OR REPLACE TABLE table_staging AS 
SELECT * FROM opta_data_ice_hockeysample_tapir_opossum.ice_hockey.fixtures;

-- Vytvorenie tabuliek dimenzií
CREATE OR REPLACE TABLE dim_team AS (
    SELECT DISTINCT
        home_uuid AS id_team,
        home AS name,
        home_short AS team_short
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_venue AS (
    SELECT DISTINCT
        venue_uuid AS id_venue,
        venue AS name
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_season AS (
    SELECT DISTINCT
        season_uuid AS id_season,
        season AS season
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_region AS (
    SELECT DISTINCT
        region_uuid AS id_region,
        region AS region
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_country AS (
    SELECT DISTINCT
        country_uuid AS id_country,
        country AS name,
        country_code AS country_code
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_competition AS (
    SELECT DISTINCT
        competition_uuid AS id_competition,
        competition AS competition
    FROM table_staging
);

CREATE OR REPLACE TABLE dim_round AS (
    SELECT DISTINCT
        DENSE_RANK() OVER (
            ORDER BY round
        ) AS id_round, 
        round AS round
    FROM table_staging
);
 
CREATE OR REPLACE TABLE dim_time AS (
SELECT DISTINCT
    TIME(date_time)::TIME(0) AS id_time,
    TIME(date_time)::TIME(0) AS played_at,
    HOUR(date_time) AS hour,
    MINUTE(date_time) AS minute
FROM table_staging
);

CREATE OR REPLACE TABLE dim_date AS (
SELECT DISTINCT
    TO_CHAR(DATE(date_time), 'YYYYMMDD') AS id_date,
    DATE(date_time) AS played_at,
    YEAR(date_time) AS year,
    MONTH(date_time) AS month,
    DAY(date_time) AS day,
    CASE DAYNAME(date_time)
        WHEN 'Mon' THEN 'Monday'
        WHEN 'Tue' THEN 'Tuesday'
        WHEN 'Wed' THEN 'Wednesday'
        WHEN 'Thu' THEN 'Thursday'
        WHEN 'Fri' THEN 'Friday'
        WHEN 'Sat' THEN 'Saturday'
        WHEN 'Sun' THEN 'Sunday' END AS weekday
FROM table_staging
);

-- Vytvorenie tabuľky faktov
CREATE OR REPLACE TABLE fact_game AS (
    SELECT
        t.game_uuid AS id_game,
        t.home_score AS home_score,
        t.away_score AS away_score,
        CASE WHEN HOME_SCORE > AWAY_SCORE THEN 1 ELSE 0 END AS home_win,
        ROUND(
            SUM(home_win) OVER (
                PARTITION BY home_uuid
            ) / COUNT() OVER (
                PARTITION BY home_uuid
        ) 100, 2)
        AS home_win_percentage,
        ROUND(
            SUM(1 - home_win) OVER (
                PARTITION BY away_uuid
            ) / COUNT() OVER (
                PARTITION BY away_uuid
        ) 100, 2) AS away_win_percentage,
        t.season_uuid AS id_season,
        t.region_uuid AS id_region,
        t.country_uuid AS id_country,
        dr.id_round AS id_round,
        dd.id_date AS id_date,
        dt.id_time AS id_time,
        t.home_uuid AS id_home_team,
        t.away_uuid AS id_away_team,
        t.venue_uuid AS id_venue,
        t.competition_uuid AS id_competition
    FROM table_staging t
    JOIN dim_round dr ON dr.round = t.round
    JOIN dim_time dt ON dt.id_time = TIME(t.date_time)::TIME(0)
    JOIN dim_date dd ON dd.id_date = TO_CHAR(DATE(t.date_time), 'YYYYMMDD')
    WHERE status = 'Played'
);

-- Odstránenie staging tabuľky
DROP TABLE table_staging;