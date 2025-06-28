-- 102-rating_shows.sql
-- Filter shows by rating threshold

-- Select shows with average rating > 10
SELECT tv_shows.title, AVG(tv_show_ratings.rating) AS avg_rating
FROM tv_shows
JOIN tv_show_ratings ON tv_shows.id = tv_show_ratings.show_id
GROUP BY tv_shows.title
HAVING avg_rating > 10
ORDER BY avg_rating DESC;
