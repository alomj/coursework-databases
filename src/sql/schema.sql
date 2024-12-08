CREATE SCHEMA IF NOT EXISTS ProjectManagement;
USE ProjectManagement;

CREATE TABLE IF NOT EXISTS Project (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS Board (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    project_id BIGINT,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Task (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    deadline DATETIME,
    status VARCHAR(50),
    board_id BIGINT,
    FOREIGN KEY (board_id) REFERENCES Board(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS Attachment (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    format VARCHAR(50),
    content BLOB,
    task_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Label (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS Tag (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT,
    label_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (label_id) REFERENCES Label(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS User (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    role VARCHAR(50),
    isBanned TINYINT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS Member (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT,
    project_id BIGINT,
    FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE,
    FOREIGN KEY (project_id) REFERENCES Project(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Assignee (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    task_id BIGINT,
    member_id BIGINT,
    FOREIGN KEY (task_id) REFERENCES Task(id) ON DELETE CASCADE,
    FOREIGN KEY (member_id) REFERENCES Member(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS Permission (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    action VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS AccessGrant (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    member_id BIGINT,
    permission_id BIGINT,
    FOREIGN KEY (member_id) REFERENCES Member(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES Permission(id) ON DELETE CASCADE
);


INSERT INTO Project (title, description) VALUES
('Project Alpha', 'Опис проекту Alpha'),
('Project Beta', 'Опис проекту Beta');

INSERT INTO Board (title, project_id) VALUES
('Board 1', 1),
('Board 2', 1),
('Board 3', 2);

INSERT INTO Task (title, description, deadline, status, board_id) VALUES
('Task 1', 'Опис Task 1', '2024-12-31 23:59:59', 'open', 1),
('Task 2', 'Опис Task 2', '2024-11-30 23:59:59', 'in progress', 1),
('Task 3', 'Опис Task 3', '2024-10-15 23:59:59', 'completed', 2);

INSERT INTO Attachment (format, content, task_id) VALUES
('pdf', 0x1234567890ABCDEF, 1),
('jpg', 0xABCDEF1234567890, 2),
('docx', 0x7890ABCDEF123456, 3);

INSERT INTO Label (name, color) VALUES
('Urgent', 'red'),
('Review', 'blue'),
('Low Priority', 'green');

INSERT INTO Tag (task_id, label_id) VALUES
(1, 1),
(2, 2),
(3, 3);

INSERT INTO User (username, password, email, role, isBanned) VALUES
('john_doe', 'password123', 'john@example.com', 'admin', 0),
('jane_smith', 'password456', 'jane@example.com', 'member', 0),
('alice_jones', 'password789', 'alice@example.com', 'member', 0);

INSERT INTO Member (user_id, project_id) VALUES
(1, 1),
(2, 1),
(3, 2);

INSERT INTO Assignee (task_id, member_id) VALUES
(1, 1),
(2, 2),
(3, 3);

INSERT INTO Permission (action) VALUES
('view'),
('edit'),
('delete');

INSERT INTO AccessGrant (member_id, permission_id) VALUES
(1, 1),
(1, 2),
(2, 1),
(2, 3),
(3, 1);