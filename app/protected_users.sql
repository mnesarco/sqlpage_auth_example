-- 1. Save the session key from cookie

SET session_key = (SELECT sqlpage.cookie('session'));

-- 2. Check authorization

SELECT * FROM x_auth_check( $session_key );

-- 3. Load a shell

SELECT * FROM x_shell('protected', '{"menu_item": [{"link":"protected_page.sql", "title":"Page1"}, "logout"], "title": "Users"}');

-- 4. Render content

SELECT 'text' AS component,
        'Welcome, ' || username || ' !' AS title,
        'This page contains two sections, **Users** section is visible only if the user has the right permissions
        while **Current User** section is visible to logged in users.' AS contents_md
        FROM x_get_user_info( $session_key );

SELECT 'text' as component, '# Current User' as contents_md;
SELECT 'table' as component;
SELECT * from x_get_user_info( $session_key );                

--
-- Section visible only to users with access to 'users' resource
--
SET has_users_access = (SELECT x_resource_access($session_key, 'users'));

SELECT 'text' as component, 
       'Users' as title,
       'Visible because you have **manager** role.' as contents_md 
    WHERE $has_users_access::boolean;

SELECT 'table' as component 
    WHERE $has_users_access::boolean;

SELECT name_, email_ FROM x_user 
    WHERE $has_users_access::boolean;

