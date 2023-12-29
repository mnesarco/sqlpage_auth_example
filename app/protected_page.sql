-- 1. Save the session key from cookie

SET session_key = (SELECT sqlpage.cookie('session'));

-- 2. Check authorization

SELECT * FROM x_auth_check( $session_key );

-- 3. Load a shell

SELECT * FROM x_shell('protected', '{"menu_item": [{"link":"protected_users.sql", "title":"Users"}, "logout"]}');

-- 4. Render content

SELECT 'text' AS component,
        'Welcome, ' || username || ' !' AS title,
        'This content is [top secret](https://youtu.be/dQw4w9WgXcQ).
        You cannot view it if you are not connected.' AS contents_md
        FROM x_get_user_info( $session_key );

