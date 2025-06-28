-- 103-rating_genres.sql
-- Get average rating per genre

-- Group by genre and calculate average rating
SELECT tv_genres.name AS genre, ROUND(AVG(tv_show_ratings.rating), 2) AS average_rating
FROM tv_genres
JOIN tv_show_genres ON tv_genres.id = tv_show_genres.genre_id
JOIN tv_show_ratings ON tv_show_genres.show_id = tv_show_ratings.show_id
GROUP BY tv_genres.name
ORDER BY average_rating DESC;
