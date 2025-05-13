-- Linkedin Database

CREATE TABLE linkedin (
    userId VARCHAR(30),
    fullName VARCHAR(100),
    email VARCHAR(100),
    location VARCHAR(100),
    industry VARCHAR(100),
    joinDate DATE,
    headline VARCHAR(150),
    postId INT,
    postDate DATE,
    content VARCHAR(500),
    visibility VARCHAR(20),
    reactionUserId VARCHAR(30),
    reactionType VARCHAR(20),
    reactionDate DATE
);

INSERT INTO linkedin VALUES
('ana.gomez',     'Ana Gómez',     'ana@abc.com',        'Madrid',     'Tech',       '2022-05-01', 'Data Scientist at ABC',         1, '2024-01-01', 'Excited to start my role!', 'public',      'carlos.ruiz',   'like',       '2024-01-02'),
('ana.gomez',     'Ana Gómez',     'ana@abc.com',        'Madrid',     'Tech',       '2022-05-01', 'Data Scientist at ABC',         1, '2024-01-01', 'Excited to start my role!', 'public',      'marta.lopez',   'celebrate',  '2024-01-02'),
('ana.gomez',     'Ana Gómez',     'ana@abc.com',        'Madrid',     'Tech',       '2022-05-01', 'Data Scientist at ABC',         2, '2024-01-03', 'Sharing my latest article.', 'connections', 'elena.munoz',   'support',    '2024-01-04'),
('carlos.ruiz',   'Carlos Ruiz',   'carlos@xyz.com',     'Barcelona',  'Tech',       '2021-08-10', 'Software Engineer at XYZ',      3, '2023-12-12', 'New backend project released.', 'public',   'ana.gomez',     'curious',    '2023-12-13'),
('carlos.ruiz',   'Carlos Ruiz',   'carlos@xyz.com',     'Barcelona',  'Tech',       '2021-08-10', 'Software Engineer at XYZ',      3, '2023-12-12', 'New backend project released.', 'public',   'laura.sanchez', 'insightful', '2023-12-14'),
('marta.lopez',   'Marta López',   'marta.hr@mail.com',  'Miami',      'HR',         '2023-01-12', 'HR Manager',                    4, '2024-01-08', 'We’re hiring! Message me!',  'public',      'javier.torres', 'like',       '2024-01-09'),
('marta.lopez',   'Marta López',   'marta.hr@mail.com',  'Miami',      'HR',         '2023-01-12', 'HR Manager',                    5, '2024-02-01', 'Work culture matters.',      'connections', 'elena.munoz',   'celebrate',  '2024-02-02'),
('laura.sanchez', 'Laura Sánchez', 'laura.iot@mail.com', 'Miami',      'Research',   '2023-07-21', 'IoT Researcher',                6, '2023-11-05', 'IoT tips and tricks.',        'public',      'tomas.navarro', 'support',    '2023-11-06'),
('elena.munoz',   'Elena Muñoz',   'elena.biz@mail.com', 'New York',   'Business',   '2022-03-17', 'Business Analyst',              7, '2024-03-10', 'Data is the new oil.',        'public',      'paula.moreno',  'like',       '2024-03-11'),
('tomas.navarro', 'Tomás Navarro', 'tomas@sec.com',      'Madrid',     'Security',   '2020-09-25', 'Cybersecurity Specialist',      8, '2024-04-01', 'Cyber awareness week!',      'public',      'andres.perez',  'curious',    '2024-04-02');

SELECT * FROM linkedin;


-- NORMALIZATION
-- Users Table: 
CREATE TABLE Users (
    userId VARCHAR(30) PRIMARY KEY,
    fullName VARCHAR(100) NOT NULL,
    email VARCHAR(100),
    location VARCHAR(100),
    industry VARCHAR(100),
    joinDate DATE NOT NULL,
    headline VARCHAR(150)
);

CREATE UNIQUE INDEX idx_unique_email_not_null
ON Users (email)
WHERE email IS NOT NULL;


INSERT INTO Users (userId, fullName, email, location, industry, joinDate, headline)
SELECT DISTINCT
    userId, fullName, email, location, industry, joinDate, headline
FROM linkedin;

SELECT * FROM Users;

INSERT INTO Users (userId, fullName, email, location, industry, joinDate, headline)
SELECT DISTINCT
    reactionUserId AS userId,
    CONCAT(
        UPPER(LEFT(reactionUserId, 1)),
        LOWER(SUBSTRING(reactionUserId, 2, CHARINDEX('.', reactionUserId) - 2)),
        ' ',
        UPPER(SUBSTRING(reactionUserId, CHARINDEX('.', reactionUserId) + 1, 1)),
        LOWER(SUBSTRING(reactionUserId, CHARINDEX('.', reactionUserId) + 2, LEN(reactionUserId)))
    ) AS fullName,
    NULL AS email,
    NULL AS location,
    NULL AS industry,
    GETDATE() AS joinDate,
    NULL AS headline
FROM linkedin
WHERE reactionUserId IS NOT NULL
    AND reactionUserId NOT IN (SELECT userId FROM Users);

SELECT * FROM Users;


-- Posts Table:
CREATE TABLE Posts (
    postId INT PRIMARY KEY,
    userId VARCHAR(30) NOT NULL,
    postDate DATE NOT NULL,
    content VARCHAR(500) NOT NULL,
    visibility VARCHAR(20) NOT NULL CHECK (visibility IN ('public', 'connections', 'private')),
    CONSTRAINT FK_Posts_Users FOREIGN KEY (userId) REFERENCES Users(userId) ON DELETE CASCADE
);

INSERT INTO Posts (postId, userId, postDate, content, visibility)
SELECT DISTINCT
    postId, userId, postDate, content, visibility
FROM linkedin;


SELECT * FROM Posts;


-- Reactions Table: 
CREATE TABLE Reactions (
    reactionId INT PRIMARY KEY,
    postId INT NOT NULL,
    userId VARCHAR(30) NOT NULL,
    reactionType VARCHAR(20) NOT NULL CHECK (reactionType IN ('like', 'celebrate', 'support', 'insightful', 'curious')),
    reactionDate DATE NOT NULL,
    CONSTRAINT FK_Reactions_Posts FOREIGN KEY (postId) REFERENCES Posts(postId) ON DELETE CASCADE,
    CONSTRAINT FK_Reactions_Users FOREIGN KEY (userId) REFERENCES Users(userId) ON DELETE NO ACTION,
    CONSTRAINT Unique_User_Post_React UNIQUE (postId, userId)
);

WITH ReactionsData AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY postId, reactionUserId) AS reactionId,
        postId,
        reactionUserId AS userId,
        reactionType,
        reactionDate
    FROM linkedin
    WHERE reactionUserId IS NOT NULL
)
INSERT INTO Reactions (reactionId, postId, userId, reactionType, reactionDate)
SELECT reactionId, postId, userId, reactionType, reactionDate
FROM ReactionsData;

SELECT * FROM Reactions;



CREATE TABLE Connections (
    connectionId INT PRIMARY KEY,
    userId1 VARCHAR(30) NOT NULL,
    userId2 VARCHAR(30) NOT NULL,
    connectionDate DATE NOT NULL,
    CONSTRAINT FK_Conn_User1 FOREIGN KEY (userId1) REFERENCES Users(userId) ON DELETE NO ACTION,
    CONSTRAINT FK_Conn_User2 FOREIGN KEY (userId2) REFERENCES Users(userId) ON DELETE NO ACTION,
    CONSTRAINT Unique_Conn UNIQUE (userId1, userId2),
    CHECK (userId1 < userId2)
);


INSERT INTO Connections (connectionId, userId1, userId2, connectionDate)
SELECT *
FROM (
    VALUES
        (1,  'ana.gomez',     'carlos.ruiz',   '2023-01-15'),
        (2,  'ana.gomez',     'marta.lopez',   '2023-01-20'),
        (3,  'carlos.ruiz',   'javier.torres', '2023-02-11'),
        (4,  'laura.sanchez', 'marta.lopez',   '2023-03-01'),
        (5,  'diego.ramos',   'javier.torres', '2022-09-19'),
        (6,  'diego.ramos',   'laura.sanchez', '2023-05-02'),
        (7,  'elena.munoz',   'laura.sanchez', '2023-05-03'),
        (8,  'elena.munoz',   'tomas.navarro', '2023-06-10'),
        (9,  'paula.moreno',  'tomas.navarro', '2023-07-18'),
        (10, 'andres.perez',  'paula.moreno',  '2024-01-05')
) AS connections(connectionId, userId1, userId2, connectionDate)
WHERE userId1 IN (SELECT userId FROM Users)
  AND userId2 IN (SELECT userId FROM Users);

SELECT * FROM Connections;

-- Additional DDL queries
ALTER TABLE Posts
ALTER COLUMN userId VARCHAR(30) NOT NULL;

ALTER TABLE Posts
ALTER COLUMN postDate DATE NOT NULL;

ALTER TABLE Posts
ALTER COLUMN content VARCHAR(500) NOT NULL;

ALTER TABLE Posts
ALTER COLUMN visibility VARCHAR(20) NOT NULL;


DROP TABLE IF EXISTS Reactions;
DROP TABLE IF EXISTS Posts;
DROP TABLE IF EXISTS Users;

-- Additional DML queries
UPDATE Reactions
SET reactionType = 'curious'
WHERE reactionType = 'insightful';


INSERT INTO Reactions (reactionId, postId, userId, reactionType, reactionDate)
VALUES (999, 1, 'elena.munoz', 'like', '2025-04-15');

DELETE FROM Reactions
WHERE reactionId = 999;


-- Views
-- View: All Posts with Author Information
CREATE VIEW View_PostsWithAuthor AS
SELECT 
    p.postId,
    p.postDate,
    p.content,
    p.visibility,
    u.userId AS authorId,
    u.fullName AS authorName,
    u.location,
    u.headline
FROM Posts p
JOIN Users u ON p.userId = u.userId;

SELECT * FROM View_PostsWithAuthor;


-- View: Connections with Full Names
CREATE VIEW View_ConnectionsWithNames AS
SELECT 
    c.connectionId,
    c.connectionDate,
    u1.fullName AS user1,
    u2.fullName AS user2
FROM Connections c
JOIN Users u1 ON c.userId1 = u1.userId
JOIN Users u2 ON c.userId2 = u2.userId;

SELECT * FROM View_ConnectionsWithNames;


-- View: Top Posts by Number of Reactions
CREATE VIEW View_TopPostsByReactions AS
SELECT 
    p.postId,
    p.content,
    COUNT(r.reactionId) AS totalReactions
FROM Posts p
LEFT JOIN Reactions r ON p.postId = r.postId
GROUP BY p.postId, p.content;

SELECT * FROM View_TopPostsByReactions;

-- Posts with more than 2 reactions
SELECT * 
FROM View_TopPostsByReactions
WHERE totalReactions > 2;


-- Author and location of the post with more reactions
SELECT 
    v.postId,
    v.content,
    v.totalReactions,
    u.fullName AS authorName,
    u.location
FROM View_TopPostsByReactions v
JOIN Posts p ON v.postId = p.postId
JOIN Users u ON p.userId = u.userId
WHERE v.totalReactions > 2
ORDER BY v.totalReactions DESC;



-- CRUD Operations
-- 
INSERT INTO Users (userId, fullName, email, location, industry, joinDate, headline)
VALUES ('roberto.mendez', 'Roberto Méndez', 'rmendez@mail.com', 'Barcelona', 'Product Management', '2023-12-01', 'Product Owner');

SELECT *  FROM Users;

SELECT userId, fullName, joinDate
FROM Users
WHERE YEAR(joinDate) = 2023;

UPDATE Posts
SET visibility = 'connections'
WHERE YEAR(postDate) = 2024;


SELECT visibility, postDate
FROM Posts;


DELETE FROM Users
WHERE LOWER(headline) LIKE '%owner%';

SELECT userID, headline
FROM Users;

SELECT userID, headline
FROM Users
WHERE LOWER(headline) LIKE '%owner%';


-- Complex queries

--1
SELECT u.fullName, COUNT(p.postId) AS totalPosts
FROM Users u
LEFT JOIN Posts p ON u.userId = p.userId
GROUP BY u.fullName
ORDER BY totalPosts DESC;


-- 2
SELECT 
    u.userId,
    u.fullName,
    COUNT(DISTINCT r.userId) AS uniqueReactors,
FROM Users u
JOIN Posts p ON u.userId = p.userId
JOIN Reactions r ON p.postId = r.postId
WHERE p.visibility = 'public'
GROUP BY u.userId, u.fullName
HAVING COUNT(DISTINCT r.userId) > 1
ORDER BY uniqueReactors DESC;

-- 3
SELECT 
    u.userId,
    u.fullName,
    COUNT(DISTINCT p.postId) AS totalPosts,
    COUNT(DISTINCT r.reactionId) AS totalReactionsReceived,
    COUNT(DISTINCT c.connectionId) AS totalConnections
FROM Users u
LEFT JOIN Posts p ON u.userId = p.userId
LEFT JOIN Reactions r ON p.postId = r.postId
LEFT JOIN Connections c ON u.userId = c.userId1 OR u.userId = c.userId2
GROUP BY u.userId, u.fullName
ORDER BY totalReactionsReceived DESC;

-- 4
SELECT 
    p.postId,
    u.fullName AS Author,
    u.industry AS Industry,
    COUNT(r.reactionId) AS TotalReactions
FROM Posts p
INNER JOIN Users u ON p.userId = u.userId
LEFT JOIN Reactions r ON p.postId = r.postId
GROUP BY p.postId, u.fullName, u.industry
ORDER BY p.postId;


-- 5
SELECT 
    userId,
    UPPER(fullName) AS upperName,
    SUBSTRING(email, CHARINDEX('@', email) + 1, LEN(email)) AS emailDomain,
    YEAR(joinDate) AS joinYear,
    DATENAME(MONTH, joinDate) AS joinMonth,
    DATENAME(WEEKDAY, joinDate) AS joinWeekday,
    DATEDIFF(YEAR, joinDate, GETDATE()) AS yearsOnPlatform
FROM Users
WHERE email IS NOT NULL
ORDER BY joinYear;


--6
SELECT 
    u.userId,
    u.fullName,
    u.joinDate,
    COUNT(c.connectionId) AS totalConnections
FROM Users u
JOIN (
    SELECT userId1 AS userId FROM Connections
    UNION ALL
    SELECT userId2 FROM Connections
) AS allConnections ON u.userId = allConnections.userId
JOIN Connections c ON c.userId1 = u.userId OR c.userId2 = u.userId
GROUP BY u.userId, u.fullName, u.joinDate
HAVING COUNT(c.connectionId) > 2
ORDER BY u.joinDate ASC;





