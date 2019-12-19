-- SQL ASSIGNMENT 


-- #1

SELECT -- COLUMNS
title 
, revenue
FROM movies_metadata_id -- DATA SOURCE
ORDER BY revenue  DESC -- CLASSIFYING DESCENDING order (highest to lowest)
LIMIT 3 -- TOP 3 rows.

-- ANSWER: Avatar, Star Wars, The Avengers 


-- #2

SELECT -- COLUMNS
title
, revenue
, release_date
FROM movies_metadata_id  -- DATA SOURCE
WHERE YEAR (release_date) = 2016 -- FILTER
ORDER BY revenue DESC LIMIT 1 -- TOP #1

-- ANSWER: Captain America: Civil War


-- #3

SELECT -- COLUMNS
YEAR (release_date) AS 'Year'
, COUNT(*) AS Nb_movies -- COUNTING number of rows to know the number of movies
, SUM(revenue) AS Total_Revenue
, MAX(revenue) AS Max_Revenue
FROM movies_metadata_id  -- DATA SOURCE
WHERE YEAR (release_date) < 2018 -- FILTER, because no revenue data from year > 2017
GROUP BY YEAR (release_date) 
ORDER BY YEAR (release_date) DESC -- CLASSIFYING YEAR PER YEAR

-- ANSWERS: 2017 - 532 Movies - Total = $15B - MAX = $1.26B
-- 2016 - 1,604 Movies - Total = $30B - MAX = $1.15B


-- #4

SELECT -- Columns
revenue as movie_revenue,
title as movie_title,
YEAR(release_date) as yr
FROM
(
SELECT -- Create subquery to extract release year and maximum revenue from movies_metadata_id table (alias t1)
YEAR(release_date) as yr,
MAX(revenue) AS max_revenue
FROM
movies_metadata_id
GROUP BY YEAR(release_date) -- group by release year
) t1
JOIN movies_metadata_id t2 -- join t1 with t2 (movies_metadata_id) on two keys (revenue & release year)
ON t2.revenue = t1.max_revenue AND t2.release_date = t1.yr
WHERE max_revenue > 0 -- filter movies with 0 revenue
ORDER BY YEAR (release_date) DESC

-- ANSWER: Beauty and the Beast, Captain Amertica: Civil War, Star Wars: The Force Awakens, Transformers: Age of Extinction, Frozen
 

-- #5.1 (UPDATED)

SELECT -- COLUMNS
SUM(m.revenue)
, c.name
FROM movies_metadata_id m -- DATA SOURCE Alias "m"
JOIN cast_id c -- SECOND DATA SOURCE Alias "c"
USING (id) -- THE JOINED VARIABLE
WHERE c.`order` = 0 -- FILTER - ONLY MAIN ACTOR
AND belongs_to_collection IS NULL -- MOVIE DOES NOT BELONG TO A COLLECTION
GROUP BY
c.name
ORDER BY SUM(m.revenue) DESC LIMIT 1 -- TOP ACTOR GENERATING THE MOST REVENUE 

-- ANSWER: Leonardo DiCaprio - Total Revenue = $3.9B


-- #5.2 (UPDATED)

-- AS WE NOW KNOW THE NAME OF THE TOP ACTOR WE CAN USE HIS NAME AS A FILTER TO SEE HIS BEST MOVIES

SELECT -- COLUMNS
title
, revenue
, YEAR (release_date)
FROM movies_metadata_id m
JOIN cast_id c 
	ON m.id = c.id 
WHERE c.name = "Leonardo DiCaprio" -- FILTER USING THE NAME
AND c.`order` = 0 -- MOVIES WHERE HE WAS MAIN ACTOR
AND belongs_to_collection IS NULL  
GROUP BY
title
, revenue
, YEAR (release_date) 
ORDER BY revenue DESC LIMIT 3 -- ORDERED BY REVENUE

-- ANSWER: Inception(2010) $825M, The Revenant(2015) $532M, The Wolf of Wall Street(2013) $392M


-- #6

SELECT -- COLUMNS
name AS NAME
, COUNT(name) AS NB_OF_MOVIES
, ROUND((SUM(revenue)/COUNT(name)),2) AS AVG_REVENUE -- AVERAGE REVENUE FOR ALL THE MOVIES HE WAS IN
FROM movies_metadata_id m
JOIN cast_id c 
	USING(id)
WHERE c.`order`= 0 -- THE ACTOR WAS THE MAIN ACTOR
GROUP BY name
HAVING NB_OF_MOVIES >= 5 -- ACTOR WHO PLAYED AT LEAST IN 5 MOVIES
ORDER BY AVG_REVENUE DESC LIMIT 1 

-- ANSWER: Daniel Radcliffe - AVG_REVENUE = $522M


-- #7

SELECT -- Columns
c.*,
d.title
FROM
(
SELECT -- create first subquery that joins 2 tables on id key (genres_id & movies_metadata_id) & returns genre and maximun revenue from THEM
name as genre,
MAX(revenue) as max_rev
FROM genres_id a
JOIN movies_metadata_id b
ON a.id = b.id -- joins on id key
WHERE YEAR(b.release_date) >= 2015 AND revenue !=0 -- filter (Filter out TV Movie genre cause 0 revenue)
GROUP BY name 
) c -- the first subquery alias c
JOIN movies_metadata_id d -- Join again with movies metadata_id table to get the title of the movie
ON c.max_rev = d.revenue -- join on revenue
ORDER BY d.revenue DESC

-- ANSWER: Star Wars (Action, Adventure, Fantasy, Science Fiction), Jurassic World (Thriller), Beauty and the Beast (Family, Romance)
-- The Fast and the Furious (Crime), Minions (Animation, Comedy), The Jungle Book (Drama), Sing (Music), the Revenant (Western)
-- Dunkirk (History, War), Now You See Me 2 (Mystery), The Conjuring 2 (Horror), Monkey Kingdom (Documentary)


-- #8.1.1

-- FIRST VERSION REMOVING MOVIES WHICH DID NOT GENERATED MONEY (AND/OR MISSING DATA)
-- THIS ALLOW TO HAVE A FAIR AVG
SELECT
td.actor_1 AS 'ACTOR #1'
, td.actor_2 AS 'ACTOR #2'
, ROUND((SUM(revenue)/COUNT(id_m)),2) AS AVG_REVENUE
, COUNT(id_m) AS NB_OF_MOVIES
FROM
	(
	SELECT
	actor_1
	, actor_2
	, id_1
	FROM
		(
		SELECT
		name AS actor_1
		, id AS id_1
		FROM cast_id
		WHERE `order` < 4 AND `character` NOT LIKE '%voice%'
		) AS tc -- MY ACTOR #1 TABLE
	JOIN 
		(
		SELECT
		name AS actor_2
		, id AS id_2
		FROM cast_id
		WHERE `order` < 4  AND `character` NOT LIKE '%voice%'
		) AS tc2 -- MY ACTOR #2 TABLE
		ON tc2.id_2 = tc.id_1 -- JOIN ON THE MOVIES ID THEY PLAYED IN
	WHERE tc2.actor_2 > tc.actor_1 -- TO AVOID DUPLICATED DUOS (reverse order)
	) td -- TABLE WITH THE 2 ACTORS AND THE MOVIE ID (will be used to join with the movie_metadata table)
JOIN
	(
	SELECT -- 
	id AS id_m
	, revenue
	FROM movies_metadata_id
	WHERE belongs_to_collection IS NULL
	AND YEAR(release_date) > 2009
	) tm -- MOVIE TABLE
	ON tm.id_m = td.id_1  -- JOINING THE IDs
WHERE revenue != 0
GROUP BY
td.actor_1
, td.actor_2
HAVING COUNT(id_m) >= 3 -- ACTORS WHO DID AT LEAST 3 MOVIES TOGETHER
ORDER BY AVG_REVENUE DESC LIMIT 10 -- DISPLAY THE TOP 10

-- ANSWER: Emma Stone & Ryan Gosling -  AVG Revenue per movie $231M - 3 movies together


-- #8.1.2

-- SECOND VERSION COUNTING THE MOVIES EVEN WITH 0 REVENUE
-- TRUE COUNT OF MOVIES (TOP 10 varies)
SELECT
td.actor_1 AS 'ACTOR #1'
, td.actor_2 AS 'ACTOR #2'
, ROUND((SUM(revenue)/COUNT(id_m)),2) AS AVG_REVENUE
, COUNT(id_m) AS NB_OF_MOVIES
FROM
	(
	SELECT -- TABLE WITH THE 2 ACTORS AND THE MOVIE ID (will be used to join with the movie_metadata table)
	actor_1
	, actor_2
	, id_1
	FROM
		(
		SELECT
		name AS actor_1
		, id AS id_1
		FROM cast_id
		WHERE `order` < 4 AND `character` NOT LIKE '%voice%'
		) AS tc -- MY ACTOR #1 TABLE
	JOIN 
		(
		SELECT
		name AS actor_2
		, id AS id_2
		FROM cast_id
		WHERE `order` < 4  AND `character` NOT LIKE '%voice%'
		) AS tc2 -- MY ACTOR #2 TABLE
		ON tc2.id_2 = tc.id_1 -- JOIN ON THE MOVIES ID THEY PLAYED IN
	WHERE tc2.actor_2 > tc.actor_1 -- TO AVOID DUPLICATED DUOS (reverse order)
	) td 
JOIN
	(
	SELECT 
	id AS id_m
	, revenue
	FROM movies_metadata_id
	WHERE belongs_to_collection IS NULL
	AND YEAR(release_date) > 2009
	) tm -- MOVIE TABLE
	ON tm.id_m = td.id_1  -- JOINING THE IDs
GROUP BY
td.actor_1
, td.actor_2
HAVING COUNT(id_m) >= 3 -- ACTORS WHO DID AT LEAST 3 MOVIES TOGETHER
ORDER BY AVG_REVENUE DESC LIMIT 10 -- DISPLAY THE TOP 10

-- ANSWER: Emma Stone & Ryan Gosling -  AVG Revenue per movie $231M - 3 movies together


-- #8.2

-- NOW THAT WE KNOW THE NAMES OF OUR BEST DUO
-- WE FILTER THE MOVIE TITLES WHERE THEY PLAYED IN
SELECT
td.actor_1 AS 'ACTOR #1'
, td.actor_2 AS 'ACTOR #2'
, revenue AS REVENUE
, title AS 'MOVIE TITLE'
FROM
(
	SELECT *
	FROM
		(
		SELECT
		name AS actor_1
		, id AS id_1
		FROM cast_id
		WHERE `order` < 4 AND `character` NOT LIKE '%voice%'
	) AS tc -- MY ACTOR #1 TABLE
	JOIN (
		SELECT
		name AS actor_2
		, id AS id_2
		FROM cast_id
		WHERE `order` < 4 AND `character` NOT LIKE '%voice%'
	) AS tc2 -- MY ACTOR #2 TABLE
		ON tc2.id_2 = tc.id_1 -- JOIN ON THE MOVIES ID THEY PLAYED IN
	WHERE tc2.actor_2 > tc.actor_1 -- TO AVOID DUPLICATED DUOS (reverse order)
) td 
JOIN
(
	SELECT 
	id AS id_m
	, title
	, revenue
	FROM movies_metadata_id
	WHERE belongs_to_collection IS NULL
	AND YEAR(release_date) > 2009
	ORDER BY revenue DESC
) tm
	ON tm.id_m = td.id_1
WHERE revenue != 0 AND td.actor_1 = 'Emma Stone' -- FILTER NAME OF ACTOR #1
AND td.actor_2 = 'Ryan Gosling' -- FILTER NAME OF ACTOR #2 
ORDER BY revenue DESC -- ORDERING MOVIES BY REVENUE GENERATED

-- ANSWER: La La Land $445M, Crazy Stupid Love $142M, Gangster Squad $105M



