-- Update a record without using SELECT
-- Example: Change all occurrences of 'Math' to 'Algebra' in subjects table

UPDATE subjects SET subject_name = 'Algebra' WHERE subject_name = 'Math';
