--create table for olympics_history
CREATE TABLE olympics_history (
id INT,
name VARCHAR,
sex VARCHAR,
age VARCHAR,
height VARCHAR,
weight VARCHAR,
team VARCHAR,
noc VARCHAR,
games VARCHAR,
year INT,
season VARCHAR,
city VARCHAR,
sport VARCHAR,
event VARCHAR,
medal VARCHAR);

--create table for olympics_noc_region
CREATE TABLE olympics_noc_region (
	noc VARCHAR,
	region VARCHAR,
	notes VARCHAR);
--select all data from the olympics_history and olympics_noc_region	
SELECT * FROM olympics_history;
SELECT * FROM olympics_noc_region;

--1 How many olympics games have been held?
SELECT COUNT (DISTINCT games)
FROM olympics_history;

--2 List down all Olympics games held so far.
SELECT DISTINCT games
FROM olympics_history;

--3 Mention the total no of nations who participated in each olympics game?
SELECT o_h.games, COUNT (DISTINCT o_r.region) AS region_count
FROM olympics_history o_h
JOIN olympics_noc_region o_r
ON o_h.noc=o_r.noc
GROUP BY o_h.games;

--4 Which year saw the highest and lowest no of countries participating in olympics?
SELECT COUNT (DISTINCT o_r.region) AS region_count, o_h.year
FROM olympics_history o_h
JOIN olympics_noc_region o_r
ON o_h.noc=o_r.noc
GROUP BY o_h.year
ORDER BY region_count DESC; TO BE REVIEWED

--5 Which nation has participated in all of the olympic games?
SELECT*
FROM (WITH nations AS 
					(SELECT games, o_r.region AS countries
					 FROM olympics_history o_h
					 JOIN olympics_noc_region o_r
					 ON o_h.noc=o_r.noc
					 GROUP BY games, o_r.region)

					SELECT COUNT (DISTINCT games) AS total_olympic_games,  countries
					FROM nations
					GROUP BY countries
					ORDER BY total_olympic_games DESC) as sub
WHERE total_olympic_games=51;

--6 Identify the sport which was played in all summer olympics.
WITH S1 AS 
(SELECT  COUNT (DISTINCT games) AS total_summer_games
FROM olympics_history
WHERE season='Summer'),

S2 AS
(SELECT DISTINCT(sport),games
 FROM olympics_history
 WHERE season ='Summer'
ORDER BY games),

S3 AS 
(SELECT sport, COUNT (games) AS no_of_games
FROM S2
GROUP BY sport)

SELECT* 
FROM S3
JOIN S1
ON S1.total_summer_games=S3.no_of_games;

--7 Fetch the top 5 athletes who have won the most gold medals.
WITH medal_count AS 
(SELECT name, COUNT(name) as total_medals
FROM olympics_history 
WHERE medal ='Gold'
GROUP BY name
ORDER BY count(name) DESC),

top_5 AS 
(SELECT *,
DENSE_RANK () OVER (ORDER BY total_medals DESC) AS top_5_medalist
FROM medal_count)

SELECT *
FROM top_5
WHERE top_5_medalist<=5;

--8 In which Sport/event, India has won highest medals.
SELECT COUNT(medal) as medal, sport
FROM olympics_history
WHERE noc = 'IND'
AND medal<>'NA'
GROUP BY sport
ORDER BY medal DESC;

/* 9 Identify which country won the most gold, most silver, most bronze medals and the most medals
in each olympic games.*/
CREATE EXTENSION TABLEFUNC;

WITH temp AS
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    		, substring(games, position(' - ' in games) + 3) as country
    		, coalesce(gold, 0) as gold
    		, coalesce(silver, 0) as silver
    		, coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    					, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_noc_region nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint)),
    	total_medals as
    		(SELECT games, nr.region as country, count(1) as total_medals
    		FROM olympics_history oh
    		JOIN olympics_noc_region nr ON nr.noc = oh.noc
    		where medal <> 'NA'
    		GROUP BY games,nr.region order BY 1, 2)
    SELECT DISTINCT t.games
    	, concat(first_value(t.country) over(partition by t.games order by gold desc)
    			, ' - '
    			, first_value(t.gold) over(partition by t.games order by gold desc)) as Max_Gold
    	, concat(first_value(t.country) over(partition by t.games order by silver desc)
    			, ' - '
    			, first_value(t.silver) over(partition by t.games order by silver desc)) as Max_Silver
    	, concat(first_value(t.country) over(partition by t.games order by bronze desc)
    			, ' - '
    			, first_value(t.bronze) over(partition by t.games order by bronze desc)) as Max_Bronze
    	, concat(first_value(tm.country) over (partition by tm.games order by total_medals desc nulls last)
    			, ' - '
    			, first_value(tm.total_medals) over(partition by tm.games order by total_medals desc nulls last)) as Max_Medals
    FROM temp t
    JOIN total_medals tm on tm.games = t.games and tm.country = t.country
    ORDER BY games;
	
--10 Identify which country won the most gold, most silver and most bronze medals in each olympic games.

WITH temp as
    	(SELECT substring(games, 1, position(' - ' in games) - 1) as games
    	 	, substring(games, position(' - ' in games) + 3) as country
            , coalesce(gold, 0) as gold
            , coalesce(silver, 0) as silver
            , coalesce(bronze, 0) as bronze
    	FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
    					, medal
    				  	, count(1) as total_medals
    				  FROM olympics_history oh
    				  JOIN olympics_noc_region nr ON nr.noc = oh.noc
    				  where medal <> ''NA''
    				  GROUP BY games,nr.region,medal
    				  order BY games,medal',
                  'values (''Bronze''), (''Gold''), (''Silver'')')
    			   AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint))
    select distinct games
    	, concat(first_value(country) over(partition by games order by gold desc)
    			, ' - '
    			, first_value(gold) over(partition by games order by gold desc)) as Max_Gold
    	, concat(first_value(country) over(partition by games order by silver desc)
    			, ' - '
    			, first_value(silver) over(partition by games order by silver desc)) as Max_Silver
    	, concat(first_value(country) over(partition by games order by bronze desc)
    			, ' - '
    			, first_value(bronze) over(partition by games order by bronze desc)) as Max_Bronze
    from temp
    order by games;
	
--11 Which countries have never won gold medal but have won silver/bronze medals?	
SELECT * FROM (
    	SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
    		FROM CROSSTAB('SELECT nr.region as country
    					, medal, count(1) as total_medals
    					FROM OLYMPICS_HISTORY oh
    					JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON nr.noc=oh.noc
    					where medal <> ''NA''
    					GROUP BY nr.region,medal order BY nr.region,medal',
                    'values (''Bronze''), (''Gold''), (''Silver'')')
    		AS FINAL_RESULT(country varchar,
    		bronze bigint, gold bigint, silver bigint)) x
    WHERE gold = 0 and (silver > 0 or bronze > 0)
    ORDER BY gold desc nulls last, silver desc nulls last, bronze desc nulls last;
	
--13 Which Sports were just played only once in the olympics?
 WITH games AS
           (SELECT DISTINCT games, sport
          	FROM olympics_history),
 sports AS
       (SELECT sport, COUNT (DISTINCT games) AS no_of_games
        FROM games
        GROUP BY sport)
 
 SELECT s.*, g.games
 FROM sports s
 JOIN games g
 ON s.sport=g.sport
 WHERE  s.no_of_games =1
 ORDER BY g.sport;

--14 Fetch the total no of sports played in each olympic games
SELECT games, COUNT (distinct sport) AS no_of_sport
FROM olympics_history
GROUP BY games
ORDER BY games DESC;

--15 Fetch details of the oldest athletes to win a gold medal.
WITH age_rank AS
				(SELECT *,
				RANK () OVER (ORDER BY age DESC) AS age_rank
				FROM olympics_history
				WHERE medal = 'Gold'
				AND age <>'NA')
SELECT *
FROM age_rank
WHERE age_rank =1;

--16 Fetch the top 5 athletes who have won the most gold medals.
WITH T1 AS 
		(SELECT name, team, medal
		FROM olympics_history
		WHERE medal = 'Gold'),
T2 AS 
	(SELECT DISTINCT name as dist_name, team, COUNT(medal) 
	FROM T1
	group by dist_name, team),
T3 AS 			
	(SELECT *,
	DENSE_RANK() OVER (ORDER BY count DESC) AS total_gold_medal
	FROM T2)
			
SELECT * 
FROM T3
WHERE total_gold_medal<=5 

--16.Fetch the top 5 athletes who have won the most medals (gold/silver/bronze).
WITH T1 AS 
(SELECT name, team, medal
				FROM olympics_history
				WHERE medal <> 'NA'),
T2 AS 
			(SELECT DISTINCT name as dist_name, team, COUNT(medal) 
			FROM T1
			group by dist_name, team),
T3 AS 			
			(SELECT *,
			DENSE_RANK() OVER (ORDER BY count DESC) AS total_medal
			FROM T2)
			
SELECT * 
FROM T3
WHERE total_medal<=5 

--17 Fetch the top 5 most successful countries in olympics. Success is defined by no of medals won.
WITH region AS 
			(SELECT o_r.region AS region, o_h.medal AS medal
			FROM olympics_history o_h
			JOIN olympics_noc_region o_r
			ON o_h.noc=o_r.noc
			WHERE medal<>'NA'),

total_medal AS 
			(SELECT DISTINCT (region), COUNT (medal) AS total_medal
			FROM region
			GROUP BY region),
successful_country AS
		   (SELECT *,
			DENSE_RANK () OVER (ORDER BY total_medal DESC ) AS rank
			FROM total_medal)
SELECT * 
FROM successful_country
WHERE rank <=5

--18 Which countries have never won gold medal but have won silver/bronze medals?
  SELECT * 
  FROM 	
  		(SELECT country, coalesce(gold,0) as gold, coalesce(silver,0) as silver, coalesce(bronze,0) as bronze
    	FROM CROSSTAB('SELECT o_r.region as country, medal, count(medal) as total_medals
    					   FROM olympics_history o_h
    					   JOIN olympics_noc_region o_r 
						   ON o_h.noc=o_r.noc
    					   WHERE medal <> ''NA''
    					   GROUP BY o_r.region,medal 
						   ORDER BY o_r.region,medal',
                          'VALUES (''Bronze''), (''Gold''), (''Silver'')')
    	AS FINAL_RESULT(country varchar,bronze bigint, gold bigint, silver bigint)) medal
    WHERE gold = 0 and (silver > 0 or bronze > 0)
    ORDER BY gold DESC nulls last, silver DESC nulls last, bronze DESC nulls last;
	
--19 List down total gold, silver and broze medals won by each country corresponding to each olympic games.
SELECT *
FROM 
	(SELECT games, region, COALESCE(gold, 0) AS gold, COALESCE (silver,0) AS silver, COALESCE (bronze,0) AS bronze
	 FROM CROSSTAB ('SELECT DISTINCT(o_r.region,games) as region,games, o_h.medal, COUNT (medal) AS total_medal
					FROM olympics_history o_h
					JOIN olympics_noc_region o_r
					ON o_h.noc=o_r.noc
					WHERE medal<> ''NA''
					GROUP BY o_r.region, o_h.medal, games
					ORDER BY region, medal',
				'VALUES (''Gold''),(''Silver''), (''Bronze'') ')
	 AS FINAL_RESULTS(games VARCHAR, region VARCHAR, gold BIGINT, silver BIGINT, bronze BIGINT)) medal
	ORDER BY region 
	
	 

 SELECT substring(games,1,position(' - ' in games) - 1) as games
        , substring(games,position(' - ' in games) + 3) as country
        , coalesce(gold, 0) as gold
        , coalesce(silver, 0) as silver
        , coalesce(bronze, 0) as bronze
    FROM CROSSTAB('SELECT concat(games, '' - '', nr.region) as games
                , medal
                , count(1) as total_medals
                FROM olympics_history oh
                JOIN olympics_noc_region nr ON nr.noc = oh.noc
                where medal <> ''NA''
                GROUP BY games,nr.region,medal
                order BY games,medal',
            'values (''Bronze''), (''Gold''), (''Silver'')')
    AS FINAL_RESULT(games text, bronze bigint, gold bigint, silver bigint);






	
	
