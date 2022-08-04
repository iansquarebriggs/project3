/* DDL */
CREATE TABLE "users" (
    "id" SERIAL PRIMARY KEY,
    "username" VARCHAR(25) NOT NULL CHECK(LENGTH(TRIM("username")) < 25),
    "date" TIMESTAMP
);
ALTER TABLE "users" ADD CONSTRAINT "unique_usernames" UNIQUE("username");
CREATE UNIQUE INDEX "date_index" ON "users" ("date");

CREATE TABLE "topics" (
    "id" SERIAL PRIMARY KEY,
    "topic" VARCHAR(30) NOT NULL CHECK(LENGTH(TRIM("topic")) < 30),
    "description" VARCHAR(500)
);
ALTER TABLE "topics" ADD CONSTRAINT "unique_topics" UNIQUE("topic");
CREATE UNIQUE INDEX "description_index" ON "topics" ("description");
ALTER TABLE "topics"
    ADD CONSTRAINT "topic_check" CHECK(LENGTH(TRIM("topic")) < 30);
ALTER TABLE "topics"
    ADD CONSTRAINT "description_check" CHECK(LENGTH(TRIM("description")) < 500);

CREATE TABLE "posts" (
    "id" SERIAL PRIMARY KEY,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE SET NULL,
    "topic_id" INTEGER NOT NULL REFERENCES "topics" ("id") ON DELETE CASCADE,
    "title" VARCHAR(100) NOT NULL CHECK(LENGTH(TRIM("title")) < 100),
    "url" VARCHAR(4000) DEFAULT NULL,
    "text_content" TEXT
);
CREATE UNIQUE INDEX "title_index" ON "posts" ("title");
CREATE UNIQUE INDEX "text_content_index" ON "posts" ("text_content");
CREATE UNIQUE INDEX "topic_id_index" ON "posts" ("topic_id");
CREATE UNIQUE INDEX "user_id_index" ON "posts" ("user_id");
ALTER TABLE "posts"
    ADD CONSTRAINT "title_check" CHECK(LENGTH(TRIM("title")) < 100);
ALTER TABLE "posts"
    ADD CONSTRAINT "url_check" CHECK(LENGTH(TRIM("url")) < 4000);
ALTER TABLE "posts"
    ADD CONSTRAINT "url || text" CHECK(("url" IS NULL AND "text_content" IS NOT
NULL)
    OR ("url" IS NOT NULL AND "text_content" IS NULL));

CREATE TABLE "comments" (
    "id" SERIAL PRIMARY KEY,
    "post_id" INTEGER,
    "comment_date" TIMESTAMP,
    "user_id" VARCHAR(25) NOT NULL CHECK(LENGTH(TRIM("user_id")) < 25),
    "text_content" TEXT NOT NULL,
    "comment_id" INT
);
ALTER TABLE "comments" ADD CONSTRAINT "fk_comment"
    FOREIGN KEY ("comment_id") REFERENCES "comments" ("id") ON DELETE CASCADE;
CREATE UNIQUE INDEX "text_index" ON "comments" ("text_content");

CREATE TABLE "votes" (
    "id" SERIAL PRIMARY KEY,
    "post_id" INTEGER REFERENCES "posts" ("id") ON DELETE CASCADE,
    "user_id" INTEGER REFERENCES "users" ("id") ON DELETE CASCADE,
    "upvote" INTEGER,
    "downvote" INTEGER
);
ALTER TABLE "votes"
    ADD CONSTRAINT "upvote1" CHECK("upvote" > 0 AND "upvote" < 2);
ALTER TABLE "votes"
    ADD CONSTRAINT "downvote1" CHECK("downvote" > -2 AND "downvote" < 0);
ALTER TABLE "votes"
    ADD CONSTRAINT "vote1" CHECK(("upvote" = 1 AND "downvote" IS NULL) OR
        ("downvote" = -1 AND "upvote" IS NULL));


/* DML */
INSERT INTO "posts" ("user_id", "topic_id", "title", "url", "text_content")
    SELECT u.user,
           t.topic,
           bp.title,
           bp.url,
           bp.text_content
    FROM bad_posts bp
    JOIN users u
    ON bp.username = u.username
    JOIN topics t
    ON t.topic = bp.topic
    WHERE (LENGTH("title") < 100);

INSERT INTO "comments" ("user_id", "post_id", "text_content")
    SELECT u.user_id,
           bc.post_id,
           bc.text_content
    FROM bad_comments bc
    INNER JOIN users u
    ON bc.username = u.username
    INNER JOIN bad_posts bp
    ON bp.id = bc.post_id;

INSERT INTO "votes" ("user_id", "post_id", "upvote", "downvote")
    SELECT u.id AS user_id,
           t1.post_id AS post_id,
           COUNT(t1.upvote) AS upvote,
           COUNT(t1.downvote) AS downvote
    FROM (
        SELECT bp.id AS post_id,
               REGEXP_SPLIT_TO_TABLE(bp.upvote, ',') AS upvote,
               REGEXP_SPLIT_TO_TABLE(bp.downvote, ',') AS downvote
        FROM bad_posts bp) t1
        JOIN users u
        ON u.username = t1.upvote AND u.username = t1.downvote
        GROUP BY 1, 2;
