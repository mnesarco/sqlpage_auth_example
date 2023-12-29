--
-- CONFIG VARS
--

SELECT x_set_config('login_form', 'signin.sql');


--
-- PREDEFINED SHELLS
--

INSERT INTO x_shell_t (id_, title, icon, link, menu_item)
VALUES 
(
    'protected',
    'Protected Page',
    'lock',
    '/',
    '{"title": "Logout", "link": "logout"}'
);

INSERT INTO x_shell_t (id_, title, icon, link)
VALUES 
(
    'public',
    'User Management App',
    'user',
    '/'
);

--
-- SECURITY
--

INSERT INTO x_role(id_, description_)
VALUES 
    ('admin', 'System Administrator'),
    ('manager', 'Manager Access');


INSERT INTO x_acl(role_id_, resource_id_, level_)
VALUES
    ('%', '%', 0),                            -- deny for all
    ('admin', '%', 99),                       -- grant max privileges to admin over all resources
    ('manager', 'users', 99);                 -- grant max privileges to manager over users resource

