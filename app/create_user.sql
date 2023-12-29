-- 1. Save the session key from cookie

SET session_key = (SELECT sqlpage.cookie('session'));

-- 2. Check authorization

SELECT * FROM x_redirect('access_error.sql')
    WHERE NOT x_resource_access($session_key, 'users', 30);

-- 3. Try to create the user

SELECT * FROM x_auth_create_user(
    :username, 
    :email, 
    :name, 
    sqlpage.hash_password(:password), 
    'create_user_welcome_message.sql?error=1&username=' || :username,
    'create_user_welcome_message.sql?username=' || :username);
