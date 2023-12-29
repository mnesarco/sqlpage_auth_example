-- Table to store global app settings
CREATE TABLE x_config
(
    key_ text not null primary key,
    value_ text not null
);

-- Table to store app users
CREATE TABLE x_user
(
    id_ serial not null primary key,
    username_ text not null unique,
    email_ text not null unique,
    password_hash_ text not null,
    name_ text not null
);

-- Table to store active sessions
CREATE TABLE x_session
(
    id_ serial not null primary key,
    key_ text not null unique,
    user_id_ integer not null references x_user(id_) ON DELETE CASCADE,
    created_at_ timestamp not null DEFAULT CURRENT_TIMESTAMP,
    expire_ timestamp not null
);

-- Table to store active session data
CREATE TABLE x_session_data
(
    session_id_ integer not null REFERENCES x_session(id_) ON DELETE CASCADE,
    key_ text not null,
    value_ jsonb not null,
    primary key (session_id_, key_)
);

-- Table to store security roles
CREATE TABLE x_role
(
    id_ text not null primary key,
    description_ text not null
);

-- Table to store security access control list (role -> *resource)
CREATE TABLE x_acl
(
    role_id_ text not null,
    resource_id_ text not null,
    level_ integer not null check (level_ between 0 and 99),
    -- Common case: 
    -- 10 = View
    -- 20 = Download
    -- 30 = Create
    -- 40 = Update
    -- 50 = Soft delete
    -- 60 = Hard delete
    PRIMARY KEY (role_id_, resource_id_)
);

-- Table to store roles assigned to users
CREATE TABLE x_user_role
(
    user_id_ integer not null REFERENCES x_user(id_) ON DELETE CASCADE,
    role_id_ text not null REFERENCES x_role(id_) ON DELETE CASCADE,
    PRIMARY KEY (user_id_, role_id_)
);

-- Table to store reusable shells
CREATE TABLE x_shell_t
(
    id_ text not null primary key,
    title text,
    description text,
    icon text,
    image text,
    footer text,
    css text,
    font text,
    font_size integer,
    javascript json,
    language text,
    link text,
    menu_item json,
    search_target text,
    norobot boolean default true,
    theme text,
    refresh text
);

-- Implicit creation of type x_shell_v
CREATE VIEW x_shell_v AS SELECT *, 'shell' as component FROM x_shell_t;