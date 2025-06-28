# SQL - More Queries

This repository contains a collection of SQL scripts designed to help one understand and practice various SQL concepts including:

- User management (`CREATE`, `DROP`, `GRANT`)
- Constraints (`NOT NULL`, `UNIQUE`, `DEFAULT`)
- Joins (`INNER JOIN`, `LEFT JOIN`)
- Subqueries and complex conditions
- Aggregation (`COUNT`, `AVG`, `GROUP BY`, `HAVING`)
- Filtering based on relationships

## File Descriptions

| Filename | Description |
|---------|-------------|
| `0-privileges.sql` | Show user privileges |
| `1-create_user.sql` | Create a new MySQL user |
| `2-remove_user.sql` | Remove a MySQL user |
| `3-force_name.sql` | Enforce NOT NULL constraint on name |
| `4-never_empty.sql` | Set default value for name |
| `5-unique_id.sql` | Unique constraint on ID |
| `6-states.sql` | Create states table |
| `7-cities.sql` | Create cities table with FK |
| `8-cities_of_california_subquery.sql` | Subquery example |
| `9-cities_by_state_join.sql` | JOIN example |
| `10-genre_id_by_show.sql` | Multiple table join |
| `11-genre_id_all_shows.sql` | LEFT JOIN example |
| `12-no_genre.sql` | NULL values with LEFT JOIN |
| `13-count_shows_by_genre.sql` | COUNT with GROUP BY |
| `14-my_genres.sql` | Complex JOIN query |
| `15-comedy_only.sql` | Specific genre selection |
| `16-shows_and_genres.sql` | Multiple JOINs |
| `100-not_my_genres.sql` | NOT IN subquery |
| `101-not_a_comedy.sql` | Complex NOT conditions |
| `102-rating_shows.sql` | Rating-based queries |
| `103-rating_genres.sql` | Genre ratings |

## How to Run
Use the MySQL CLI:
```bash
mysql -u <username> -p <database_name> < filename.sql
