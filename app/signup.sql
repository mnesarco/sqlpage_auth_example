-- 1. Save the session key from cookie

SET session_key = (SELECT sqlpage.cookie('session'));

-- 2. Check authorization

SELECT * FROM x_redirect('access_error.sql')
    WHERE NOT x_resource_access($session_key, 'users', 30);

-- 3. Load a shell

SELECT * FROM x_shell('protected');

-- 4. Render content

SELECT 'form' AS component,
    'Create a new user account' AS title,
    'Sign up' AS validate,
    'create_user.sql' AS action;

SELECT 'username' AS name, true as required;
SELECT 'name' AS name, true as required;
SELECT 'email' AS name, true as required;

SELECT 
    'password' AS name, 
    'password' AS type, 
    true as required,
    '^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$' AS pattern, 
    'Password must be at least 8 characters long and contain at least one letter and one number.' AS description;

SELECT 
    'terms' AS name, 
    'I accept the terms and conditions' AS label, 
    TRUE AS required, 
    FALSE AS value, 
    'checkbox' AS type;