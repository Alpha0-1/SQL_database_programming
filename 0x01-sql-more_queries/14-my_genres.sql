-- 14-my_genres.sql
-- Complex JOIN to get shows of a particular user's favorite genre

-- Assume favorites stored in user_favorites table
SELECT tv_shows.title
FROM tv_shows
JOIN tv_show_genres ON tv_shows.id = tv_show_genres.show_id
JOIN tv_genres ON tv_show_genres.genre_id = tv_genres.id
WHERE tv_genres.name = 'Comedy'
ORDER BY tv_shows.title ASC;
