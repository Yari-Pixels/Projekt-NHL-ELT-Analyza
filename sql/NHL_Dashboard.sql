-- Graf 1 - Percentuálna úspešnosť tímov doma a vonku
SELECT DISTINCT dt.name AS Team, ht.home_win_percentage AS "Home Win Percentage", at.away_win_percentage AS "Away Win Percentage" FROM dim_team dt
JOIN fact_game ht ON dt.id_team = ht.id_home_team
JOIN fact_game at ON dt.id_team = at.id_away_team;


-- Graf 2 - Heat Mapa počtu gólov skórovaných v zápase
SELECT 
    fg.home_score AS "Goals Scored By Home Team",
    fg.away_score AS "Goals Scored By Away Team"
FROM fact_game fg;


-- Graf 3 - Vzťah medzi víťazstvami a inkasovanými gólmi
SELECT 
    dt.name AS "Team",
    SUM(CASE WHEN fg.id_home_team = dt.id_team THEN fg.home_win WHEN fg.id_away_team = dt.id_team THEN 1 - fg.home_win ELSE 0 END) AS "Wins",
    SUM(CASE WHEN fg.id_home_team = dt.id_team THEN fg.away_score WHEN fg.id_away_team = dt.id_team THEN fg.home_score ELSE 0 END) AS "Goals Against"
FROM fact_game fg
JOIN dim_team dt ON dt.id_team = fg.id_away_team OR dt.id_team = fg.id_home_team
JOIN dim_round dr ON dr.id_round = fg.id_round
WHERE dr.round = 'Regular Season'
GROUP BY "Team"
ORDER BY "Goals Against" ASC;


-- Graf 4 - Množstvo zápasov odohraných v jednotlivých časoch podľa EST
SELECT 
    TO_VARCHAR(DATEADD(HOUR, -5, dt.played_at), 'HH24:MI') AS "Match Start",
    COUNT(fg.id_game) AS "Games Played"
FROM fact_game fg
JOIN dim_time dt ON dt.id_time = fg.id_time
GROUP BY "Match Start";


-- Graf 5 - Góly skórované prvým, druhým, posledným tímom a ligový priemer počas základnej časti
SELECT 
    dd.played_at AS "Date",
    SUM(CASE WHEN fg.id_home_team = 'bmq50tqou0wnfp2tyd5s1f2g2' THEN fg.home_score WHEN fg.id_away_team = 'bmq50tqou0wnfp2tyd5s1f2g2' THEN fg.away_score ELSE 0 END) OVER (
        ORDER BY dd.played_at ASC
    )
    AS "Colorado Avalanche Goals",
    SUM(CASE WHEN fg.id_home_team = '571daqoft6kyltch2cxzdpus2' THEN fg.home_score WHEN fg.id_away_team = '571daqoft6kyltch2cxzdpus2' THEN fg.away_score ELSE 0 END) OVER (
        ORDER BY dd.played_at ASC
    ) AS "Montreal Canadiens Goals",
    SUM(CASE WHEN fg.id_home_team = 'dqexe8lb66wdsrnpygbj6uefs' THEN fg.home_score WHEN fg.id_away_team = 'dqexe8lb66wdsrnpygbj6uefs' THEN fg.away_score ELSE 0 END) OVER (
        ORDER BY dd.played_at ASC
    ) AS "Tampa Bay Lightning Goals",
    ROUND(SUM(fg.home_score + fg.away_score) OVER (
        ORDER BY dd.played_at ASC
    ) / (SELECT COUNT(DISTINCT fg.id_home_team) FROM fact_game fg), 0) AS "League Average"
FROM fact_game fg
JOIN dim_date dd ON dd.id_date = fg.id_date
JOIN dim_round dr ON dr.id_round = fg.id_round
WHERE dr.round = 'Regular Season'
ORDER BY dd.played_at ASC;

-- Graf 6 - 15 najvyťaženejších štadiónov počas sezóny
SELECT 
    dv.name AS "Venue", 
    CASE WHEN dr.round = 'Pre Season' THEN 'Temporary' ELSE dt.name END AS "Team", 
    COUNT(*) AS "Games Played",
    CONCAT("Venue", ' / ', "Team") AS "Venue / Team"
FROM fact_game fg
JOIN dim_venue dv ON dv.id_venue = fg.id_venue
JOIN dim_team dt ON dt.id_team = fg.id_home_team
JOIN dim_round dr ON dr.id_round = fg.id_round
GROUP BY "Venue", "Team"
ORDER BY "Games Played" DESC
LIMIT 15;
