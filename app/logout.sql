-- 1. Clear the session if any on server and client side

SELECT * FROM x_auth_logout( sqlpage.cookie('session') );

-- 2. Redirect somewhere

SELECT * FROM x_redirect('/');
