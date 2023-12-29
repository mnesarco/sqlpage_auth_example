INSERT INTO x_user(username_, email_, password_hash_, name_)
VALUES 
--- Admin User with all privileges
(
    'admin',
    'admin@example.com',
    '$argon2id$v=19$m=19456,t=2,p=1$Y52o33gmlMobLP2a6OHYoA$kPlz7M9kvsJD3aE6LNNCIcHWYZhhQJU8xpPl7L5afyQ', -- demo
    'Administrator'
),
--- Normal user with no special privileges
(
    'user',
    'user@example.com',
    '$argon2id$v=19$m=19456,t=2,p=1$Y52o33gmlMobLP2a6OHYoA$kPlz7M9kvsJD3aE6LNNCIcHWYZhhQJU8xpPl7L5afyQ', -- demo
    'Demo User'
),
--- Manager user with manager privileges
(
    'user2',
    'user2@example.com',
    '$argon2id$v=19$m=19456,t=2,p=1$Y52o33gmlMobLP2a6OHYoA$kPlz7M9kvsJD3aE6LNNCIcHWYZhhQJU8xpPl7L5afyQ', -- demo
    'Demo Manager'
);


SELECT x_grant_roles('user2', 'manager');
SELECT x_grant_roles('admin', 'admin');

