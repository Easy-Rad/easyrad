BEGIN TRANSACTION;
CREATE TABLE IF NOT EXISTS "body_part" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
) STRICT;
CREATE TABLE IF NOT EXISTS "examination" (
	"id"	INTEGER,
	"code"	TEXT NOT NULL UNIQUE COLLATE NOCASE,
	"name"	TEXT NOT NULL UNIQUE COLLATE NOCASE,
	"modality"	INTEGER NOT NULL,
	"body_part"	INTEGER NOT NULL,
	"topic"	INTEGER,
	PRIMARY KEY("id"),
	FOREIGN KEY("body_part") REFERENCES "body_part"("id") ON UPDATE CASCADE ON DELETE RESTRICT,
	FOREIGN KEY("modality") REFERENCES "modality"("id") ON UPDATE CASCADE ON DELETE RESTRICT
) STRICT;
CREATE TABLE IF NOT EXISTS "label" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE COLLATE NOCASE,
	"examination"	INTEGER NOT NULL,
	PRIMARY KEY("id"),
	FOREIGN KEY("examination") REFERENCES "examination"("id") ON UPDATE CASCADE ON DELETE RESTRICT
) STRICT;
CREATE TABLE IF NOT EXISTS "modality" (
	"id"	INTEGER,
	"name"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id")
) STRICT;
CREATE INDEX IF NOT EXISTS "label_examination" ON "label" (
	"examination"
);
CREATE INDEX IF NOT EXISTS "modality_body_part_examination_name" ON "examination" (
	"modality",
	"body_part",
	"name"
);
COMMIT;
