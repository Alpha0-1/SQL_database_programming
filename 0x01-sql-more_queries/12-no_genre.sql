-- 12-no_genre.sql
-- Find shows with no genre linked

-- Use IS NULL after LEFT JOIN to find unmatched records
SELECT tv_shows.title
FROM tv_shows
LEFT JOIN tv_show_genres ON tv_shows.id = tv_show_genres.show_id
WHERE tv_show_genres.genre_id IS NULL
ORDER BY tv_shows.title ASC;
