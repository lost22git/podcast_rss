DROP TABLE IF EXISTS channel;
CREATE TABLE channel (
    id VARCHAR NOT NULL,
    rss VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    description VARCHAR,
    author VARCHAR,
    image VARCHAR,
    "language" VARCHAR,
    CONSTRAINT channel_pk PRIMARY KEY (id)
);


DROP TABLE IF EXISTS channel_item;
CREATE TABLE channel_item (
    id VARCHAR NOT NULL,
    channel_id VARCHAR NOT NULL,
    title VARCHAR NOT NULL,
    subtitle VARCHAR,
    description VARCHAR,
    pub_date VARCHAR,
    image VARCHAR,
    duration VARCHAR,
    url VARCHAR,
    "type" VARCHAR,
    "length" VARCHAR,
    CONSTRAINT channel_item_pk PRIMARY KEY (id)
);
