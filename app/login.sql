-- 1. Try to authenticate user. If authentication fails, the rest will not execute.

SELECT * FROM x_auth_login(:username, :password);

-- 2. Start an authenticated session

SELECT * FROM x_auth_grant(:username, 60, false);

-- 3. Redirect to whatever you send authenticated users

SELECT * FROM x_redirect('protected_page.sql');