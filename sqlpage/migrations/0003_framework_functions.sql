-- ############################################################################
-- COOKIES
-- ############################################################################

-- Save cookie
CREATE OR REPLACE FUNCTION x_cookie_set(p_name text, p_value text, p_secure boolean default true)
RETURNS TABLE(component text, name text, value text, secure boolean) AS
$$
    SELECT 
        'cookie'  as component, 
        p_name    as name, 
        p_value   as value, 
        p_secure  as secure;
$$ LANGUAGE sql;

-- Delete cookie
CREATE OR REPLACE FUNCTION x_cookie_clear(p_name text, p_value text)
RETURNS TABLE(component text, name text, remove boolean) AS
$$
    SELECT 
        'cookie'  as component, 
        p_name    as name, 
        true      as remove;
$$ LANGUAGE sql;

-- ############################################################################
-- SESSION
-- ############################################################################

-- Get logged in user info
CREATE OR REPLACE FUNCTION x_get_user_info(p_session_key text) 
RETURNS SETOF x_user_info_t AS
$$
    SELECT 
        u.id_       as id, 
        s.id_       as session_id, 
        s.key_      as session_key, 
        u.username_ as username, 
        u.name_     as name, 
        u.email_    as email
    FROM x_session s LEFT JOIN x_user u ON s.user_id_ = u.id_
    WHERE s.key_ = p_session_key;
$$ LANGUAGE sql;

-- ############################################################################
-- NAVIGATION
-- ############################################################################

-- Redirect
CREATE OR REPLACE FUNCTION x_redirect(p_page text) 
RETURNS x_redirect_t AS
$$
    SELECT 
        'redirect'  as component,
        p_page      as link;
$$ LANGUAGE sql;

-- ############################################################################
-- CONFIGURATION
-- ############################################################################

-- Get global app setting value
CREATE OR REPLACE FUNCTION x_get_config(p_key text, p_default text default null)
RETURNS text AS
$$
DECLARE
    l_value text;
BEGIN
    SELECT value_ 
        INTO l_value     
        FROM x_config
        WHERE key_ = p_key;

    IF FOUND THEN
        RETURN l_value;
    ELSE
        RETURN p_default;
    END IF;
END
$$ LANGUAGE plpgsql;

-- Set global app setting value
CREATE OR REPLACE FUNCTION x_set_config(p_key text, p_value text)
RETURNS void AS
$$
    INSERT INTO x_config(key_, value_)
    VALUES (p_key, p_value)
    ON CONFLICT (key_) DO UPDATE SET value_ = p_value;
$$ LANGUAGE sql;


-- ############################################################################
-- AUTHENTICATION
-- ############################################################################

-- Login component
CREATE OR REPLACE FUNCTION x_auth_login(p_username text, p_password text, p_login_err_form_page text default null) 
RETURNS SETOF x_auth_login_t AS
$$
    SELECT 
        'authentication'                 as component,
        COALESCE(
            p_login_err_form_page, 
            x_get_config('login_form')::text) || '?error' as link,
        (SELECT password_hash_ 
           FROM x_user 
           WHERE username_ = p_username) as password_hash,
        p_password                       as password;
$$ LANGUAGE sql;


-- Start an authenticated session
CREATE OR REPLACE FUNCTION x_auth_grant(p_username text, p_duration_mins integer, p_secure boolean default true)
RETURNS SETOF x_auth_grant_t AS
$$
    INSERT INTO x_session (key_, user_id_, created_at_, expire_)
    VALUES (
        gen_random_uuid(), 
        (SELECT id_ FROM x_user WHERE username_ = p_username),
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP + (p_duration_mins::text || ' minutes')::interval
    )
    RETURNING 
        'cookie'    AS component,
        'session'   AS name,
        key_        AS value,
        p_secure    AS secure;
$$ LANGUAGE sql;


-- Check if user is authenticated or redirect
CREATE OR REPLACE FUNCTION x_auth_check(p_session_key text, p_login_page text default null)
RETURNS SETOF x_redirect_t AS
$$
DECLARE
    l_login_page text;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM x_session WHERE key_ = p_session_key) THEN
        l_login_page = COALESCE(p_login_page, x_get_config('login_form')::text);
        RETURN QUERY SELECT * FROM x_redirect(l_login_page || '?error');
    END IF;
END
$$ LANGUAGE plpgsql;


-- Destroy the curent session
CREATE OR REPLACE FUNCTION x_auth_logout(p_session_key text)
RETURNS TABLE(component text, name text, remove boolean) AS
$$
BEGIN
    DELETE FROM x_session WHERE key_ = p_session_key;
    RETURN QUERY SELECT 'cookie' AS component, 'session' AS name, true AS remove;
END
$$ LANGUAGE plpgsql;


-- Create user
CREATE OR REPLACE FUNCTION x_auth_create_user(p_username text, p_email text, p_name text, p_password_hash text, p_error_page text, p_success_page text default null)
RETURNS SETOF x_redirect_t AS
$$
BEGIN
    IF EXISTS(SELECT 1 FROM x_user WHERE username_ = LOWER(TRIM(p_username)) OR email_ = LOWER(TRIM(p_email))) THEN
        RETURN QUERY 
            SELECT 
                'redirect' as component, 
                p_error_page as link;
    ELSE
        INSERT INTO x_user(username_, email_, name_, password_hash_)
        VALUES (LOWER(TRIM(p_username)), LOWER(TRIM(p_email)), p_name, p_password_hash);

        RETURN QUERY
            SELECT 
                'redirect' AS component,
                COALESCE(p_success_page, p_error_page) AS link;    
    END IF;
END
$$ LANGUAGE plpgsql;


-- ############################################################################
-- AUTHORIZATION
-- ############################################################################

-- Grant roles to an user
CREATE OR REPLACE FUNCTION x_grant_roles(p_username text, variadic p_roles text[])
RETURNS VOID AS
$$
DECLARE
    uid integer;
BEGIN
    SELECT id_ into uid FROM x_user WHERE username_ = p_username;
    IF FOUND THEN 
        FOR i IN 1..array_upper(p_roles,1) LOOP
            IF EXISTS(SELECT id_ FROM x_role WHERE id_ = p_roles[i]) THEN
                INSERT INTO x_user_role(user_id_, role_id_)
                    VALUES (uid, p_roles[i])
                    ON CONFLICT DO NOTHING;
            END IF;
        END LOOP;
    END IF;
END
$$ LANGUAGE plpgsql;

-- Revoke roles from an user
CREATE OR REPLACE FUNCTION x_revoke_roles(p_username text, variadic p_roles text[])
RETURNS VOID AS
$$
DECLARE
    uid integer;
BEGIN
    SELECT id_ into uid FROM x_user WHERE username_ = p_username;
    IF FOUND THEN
        FOR i IN 1..array_upper(p_roles,1) LOOP
            DELETE FROM x_user_role WHERE user_id = uid AND role_id_ = p_roles[i];
        END LOOP;
    END IF;
END
$$ LANGUAGE plpgsql;

-- Check if the current session has permission at some minimum level over a resource
CREATE OR REPLACE FUNCTION x_resource_access(p_session_key text, p_resource text, p_level int default 10)
RETURNS boolean AS
$$
DECLARE
    uid integer;
    level int := 0;
BEGIN
    SELECT id INTO uid FROM x_get_user_info( p_session_key );
    IF FOUND THEN
        SELECT acl.level_ 
        INTO level
        FROM x_user_role r, x_acl acl
        WHERE 
            r.user_id_ = uid 
            AND r.role_id_ LIKE acl.role_id_ 
            AND p_resource LIKE acl.resource_id_
        ORDER BY acl.level_ DESC
        LIMIT 1;
    END IF;
    RETURN FOUND AND level >= p_level;
END
$$ LANGUAGE plpgsql;

-- Check if current session has any of the passed roles
CREATE OR REPLACE FUNCTION x_role_access(p_session_key text, variadic p_role text[])
RETURNS boolean AS
$$
DECLARE
    uid integer;
BEGIN
    SELECT id INTO uid FROM x_get_user_info( p_session_key );
    RETURN FOUND AND EXISTS(SELECT 1 FROM x_user_role WHERE user_id_ = uid AND role_id_ = ANY(p_role));
END
$$ LANGUAGE plpgsql;


-- ############################################################################
-- SHELLS
-- ############################################################################


--
-- x_shell( shell_id, overides )
-- Load a shell component from table(x_shell_t) by id and overrides the passed attributes.
--
-- Example (Load extended-layout shell with title=Products):
--
--   SELECT * FROM x_shell('extended-layout', json_build_object('title', 'Products'))
--
CREATE OR REPLACE FUNCTION x_shell(p_id text, p_overrides json default '{}'::json)
RETURNS SETOF x_shell_v AS 
$$
BEGIN
    RETURN QUERY
        SELECT
            id_,
            coalesce(p_overrides->>'title', title) as title,
            coalesce(p_overrides->>'description', description) as description,
            coalesce(p_overrides->>'icon', icon) as icon,
            coalesce(p_overrides->>'image', image) as image,
            coalesce(p_overrides->>'footer', footer) as footer,
            coalesce(p_overrides->>'css', css) as css,
            coalesce(p_overrides->>'font', font) as font,
            coalesce((p_overrides->>'font_size')::int, font_size) as font_size,
            coalesce(p_overrides->'javascript', javascript) as javascript,
            coalesce(p_overrides->>'language', language) as language,
            coalesce(p_overrides->>'link', link) as link,
            coalesce(p_overrides->'menu_item', menu_item) as menu_item,
            coalesce(p_overrides->>'search_target', search_target) as search_target,
            coalesce((p_overrides->>'norobot')::boolean, norobot) as norobot,
            coalesce(p_overrides->>'theme', theme) as theme,
            coalesce(p_overrides->>'refresh', refresh) as refresh,
            component
        FROM x_shell_v
        WHERE id_ = p_id;
END
$$ LANGUAGE plpgsql;
