-- 1. Load a shell

SELECT * FROM x_shell('public');

-- 2. Render the content

SELECT 'hero' AS component,
    'Authorization Error' AS title,
    'You are not authorized to use this feature' AS description_md,
    'signin.sql' AS link,
    'Login as an authorized user' AS link_text;
