BEGIN TRANSACTION;
CREATE TABLE `tags` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT NOT NULL UNIQUE
);
CREATE TABLE `people` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`name`	TEXT NOT NULL UNIQUE
);
CREATE TABLE `events_tags` (
	`event_id`	INTEGER NOT NULL,
	`tag_id`	INTEGER NOT NULL,
	PRIMARY KEY(`event_id`,`tag_id`),
	FOREIGN KEY(`event_id`) REFERENCES events(id),
	FOREIGN KEY(`tag_id`) REFERENCES tags(id)
);

CREATE TABLE `events_people` (
	`event_id`	INTEGER NOT NULL,
	`person_id`	INTEGER NOT NULL,
	PRIMARY KEY(`event_id`,`person_id`),
	FOREIGN KEY(`event_id`) REFERENCES events(id),
	FOREIGN KEY(`person_id`) REFERENCES people(id)

);

CREATE TABLE `events` (
	`id`	INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
	`description`	TEXT,
	`created_at`	TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
COMMIT;
