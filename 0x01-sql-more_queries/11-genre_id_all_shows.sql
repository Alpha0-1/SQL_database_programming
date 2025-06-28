-- 11-genre_id_all_shows.sql
-- LEFT JOIN example to include shows without genre

-- Left join to get all shows even if no genre assigned
SELECT tv_shows.title, tv_genres.name
FROM tv_shows
LEFT JOIN tv_show_genres ON tv_shows.id = tv_show_genres.show_id
LEFT JOIN tv_genres ON tv_show_genres.genre_id = tv_genres.id
ORDER BY tv_shows.title ASC;
