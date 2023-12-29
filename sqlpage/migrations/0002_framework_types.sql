-- Redirect component schema
CREATE TYPE x_redirect_t AS (
    component text, 
    link text
);

-- Authentication component schema
CREATE TYPE x_auth_login_t AS (
    component text, 
    link text, 
    password_hash text, 
    password text
);

-- Save auth session schema
CREATE TYPE x_auth_grant_t AS (
    component text, 
    name text, 
    value text, 
    secure boolean
);

-- Logged in user schema
CREATE TYPE x_user_info_t AS (
    id integer, 
    session_id integer, 
    session_key text, 
    username text, 
    name text, 
    email text
);
