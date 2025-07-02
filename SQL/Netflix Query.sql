USE Netflix;
GO

-- A Sneak Peak to the data
SELECT TOP(5) * FROM content_library

-- Records Count
SELECT COUNT(id) FROM content_library

-- Checking Nulls
SELECT
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN id IS NULL THEN 1 ELSE 0 END) AS id_nulls,
    SUM(CASE WHEN title IS NULL THEN 1 ELSE 0 END) AS title_nulls,
    SUM(CASE WHEN type IS NULL THEN 1 ELSE 0 END) AS type_nulls,
    SUM(CASE WHEN description IS NULL THEN 1 ELSE 0 END) AS description_nulls,
    SUM(CASE WHEN release_year IS NULL THEN 1 ELSE 0 END) AS release_year_nulls,
    SUM(CASE WHEN age_certification IS NULL THEN 1 ELSE 0 END) AS age_certification_nulls,
    SUM(CASE WHEN runtime IS NULL THEN 1 ELSE 0 END) AS runtime_nulls,
    SUM(CASE WHEN genres IS NULL THEN 1 ELSE 0 END) AS genres_nulls,
    SUM(CASE WHEN production_countries IS NULL THEN 1 ELSE 0 END) AS production_countries_nulls,
    SUM(CASE WHEN seasons IS NULL THEN 1 ELSE 0 END) AS seasons_nulls,
    SUM(CASE WHEN imdb_id IS NULL THEN 1 ELSE 0 END) AS imdb_id_nulls,
    SUM(CASE WHEN imdb_score IS NULL THEN 1 ELSE 0 END) AS imdb_score_nulls,
    SUM(CASE WHEN imdb_votes IS NULL THEN 1 ELSE 0 END) AS imdb_votes_nulls,
    SUM(CASE WHEN tmdb_popularity IS NULL THEN 1 ELSE 0 END) AS tmdb_popularity_nulls,
    SUM(CASE WHEN tmdb_score IS NULL THEN 1 ELSE 0 END) AS tmdb_score_nulls
FROM content_library;

-- Delete the Missing Title
DELETE FROM content_library
WHERE title IS NULL;

-- Fill Missing Description with 'No Description'
UPDATE content_library
SET description = 'No Description'
WHERE description IS NULL;

-- Fill Missing Age Certification with 'Unrated'
UPDATE content_library
SET age_certification = 'Unrated'
WHERE age_certification IS NULL;

-- Fill Missing Imdb Id with 'N/A'
UPDATE content_library
SET imdb_id = 'N/A'
WHERE imdb_id IS NULL;

-- Fill Missing Countries with 'Unkown'
UPDATE content_library
SET production_countries = 'Unkown'
WHERE production_countries = '[]';


-- Fill Missing Values for Imdb Score, Imdb Votes, Tmdb Popularity, Tmdb Score with Average
SELECT AVG(CAST(imdb_score AS FLOAT)) AS avg_imdb_score
FROM content_library
WHERE imdb_score IS NOT NULL;

UPDATE content_library
SET imdb_score = 6.5
WHERE imdb_score IS NULL;

SELECT AVG(CAST(imdb_votes AS FLOAT)) AS avg_imdb_votes
FROM content_library
WHERE imdb_votes IS NOT NULL;

UPDATE content_library
SET imdb_votes = 23439.4
WHERE imdb_votes IS NULL;

SELECT AVG(CAST(tmdb_popularity AS FLOAT)) AS avg_tmdb_popularity
FROM content_library
WHERE tmdb_popularity IS NOT NULL;

UPDATE content_library
SET tmdb_popularity = 22.6
WHERE tmdb_popularity IS NULL;


SELECT AVG(CAST(tmdb_score AS FLOAT)) AS avg_tmdb_score
FROM content_library
WHERE tmdb_score IS NOT NULL;

UPDATE content_library
SET tmdb_score = 6.8
WHERE tmdb_score IS NULL;
-- We have 3743 NULL in Seasons and we need to check if it's only because Movies has no seasons or we have NULLS in Shows
-- We can check the NULL in Show OR check the records of Movies

-- I Will check the records of Movies 
SELECT COUNT(*) FROM content_library
WHERE type = 'MOVIE' AND seasons IS NULL
-- It's the same number of NULL so we don't need to fix it

-- We can also check the NULL in Show
SELECT COUNT(*) FROM content_library
WHERE type = 'SHOW' AND type IS NULL
-- It's zero, so we are fine

-- Check Dublicates
SELECT 
    title, 
    release_year, 
    type,
    COUNT(*) AS count
FROM content_library
GROUP BY title, release_year, type
HAVING COUNT(*) > 1;
-- We have 0 Dublicates, so let's start the analysis

-- Movies vs Shows
SELECT 
    type, 
    COUNT(*) AS count,
    CONCAT(CAST(Count(*) * 100 / SUM(COUNT(*)) OVER () AS DECIMAL(5,2)) , ' %') AS Percentage
FROM content_library
GROUP BY type;

-- Total Show by Year
SELECT
    release_year,
    COUNT(*) AS Number_of_Shows
FROM content_library
GROUP BY release_year
ORDER BY Number_of_Shows DESC;

-- Total Show by Country
SELECT
    production_countries,
    COUNT(*) AS Number_of_Shows
FROM content_library
WHERE production_countries <> 'Unknown'
GROUP BY production_countries
ORDER BY Number_of_Shows DESC;

-- Top 10 Shows
SELECT
    title,
    type,
    release_year,
    imdb_score,
    imdb_votes
FROM content_library
ORDER BY imdb_score DESC, imdb_votes DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Total Shows for each Genre and Average Imdb Score
SELECT 
    LTRIM(RTRIM(value)) AS genre,
    COUNT(*) AS count,
    AVG(imdb_score) AS avg_imdb_score
FROM content_library
CROSS APPLY STRING_SPLIT(
                         REPLACE(
                                 REPLACE(genres, '[', '')
                                  ,']', '')
                          ,',')
WHERE genres IS NOT NULL AND genres <> '[]'
GROUP BY LTRIM(RTRIM(value))
ORDER BY count DESC;

-- Total Titles for each Age Certification and the Avgerage Imdb Score
SELECT 
    age_certification,
    COUNT(*) AS total_titles,
    AVG(imdb_score) AS avg_score
FROM content_library
GROUP BY age_certification
ORDER BY total_titles DESC;

-- Top 10 Movies Duration
SELECT 
    title,
    CAST(runtime / 60 AS VARCHAR) + ':' + 
    RIGHT('0' + CAST(runtime % 60 AS VARCHAR), 2) AS Duration
FROM content_library
WHERE runtime IS NOT NULL AND type = 'MOVIE'
ORDER BY runtime DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Top 10 Shows' episode Duration
SELECT 
    title,
    CAST(runtime / 60 AS VARCHAR) + ':' + 
    RIGHT('0' + CAST(runtime % 60 AS VARCHAR), 2) AS Episode_Duration
FROM content_library
WHERE runtime IS NOT NULL AND type = 'SHOW'
ORDER BY runtime DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- The duration look wierd so let me check the outliers 
SELECT 
    title, 
    type, 
    runtime,
    seasons
FROM content_library
WHERE (
    (type = 'MOVIE' AND (runtime < 40 OR runtime > 240)) OR
    (type = 'SHOW' AND (runtime < 10 OR runtime > 90))
)
ORDER BY runtime DESC;

-- The data is FAKE xd
