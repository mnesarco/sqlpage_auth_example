-- 1. Save the session key from cookie

SET session_key = (SELECT sqlpage.cookie('session'));
SET is_logged_in = (SELECT EXISTS(SELECT 1 FROM x_get_user_info( $session_key )));

-- 2. Load a shell

SELECT * FROM x_shell('public', '{"menu_item": ["logout"]}')
    WHERE $is_logged_in::boolean;

SELECT * FROM x_shell('public', '{"menu_item": ["signin"]}')
    WHERE NOT $is_logged_in::boolean;

-- 3. Render content

SELECT 'hero' AS component,
    'SQLPage Authentication Demo' AS title,
    'This application requires signing up to view the protected page.' AS description_md,
    'images/db1.png' AS image,
    'protected_page.sql' AS link,
    'Access protected page' AS link_text;

SELECT 'hero' AS component,
    'Users Page' AS title,
    'Manage Applications Users if you have enough authorizations' AS description_md,
    'protected_users.sql' AS link,
    'Mange Users' AS link_text;

SELECT
    'current_user' as component,
    'user' as icon,
    x.name
    FROM x_get_user_info( $session_key ) x;
