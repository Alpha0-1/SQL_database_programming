-- 16-shows_and_genres.sql
-- Multiple joins to list shows and their genres

-- List all shows and their associated genres
SELECT tv_shows.title, tv_genres.name AS genre
FROM tv_shows
JOIN tv_show_genres ON tv_shows.id = tv_show_genres.show_id
JOIN tv_genres ON tv_show_genres.genre_id = tv_genres.id
ORDER BY tv_shows.title, tv_genres.name;
