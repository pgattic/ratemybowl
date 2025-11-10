CREATE TABLE "restroom"(
    "restroom_id" BIGINT NOT NULL,
    "location_id" BIGINT NOT NULL,
    "name" TEXT NOT NULL,
    "gender" VARCHAR(255) NOT NULL CHECK ("gender" IN ('male', 'female', 'unisex')),
    "coordinate" geography NOT NULL
);
ALTER TABLE
    "restroom" ADD PRIMARY KEY("restroom_id");
CREATE TABLE "review"(
    "review_id" BIGINT NOT NULL,
    "restroom_id" BIGINT NOT NULL,
    "user_id" UUID NOT NULL,
    "stars" SMALLINT NOT NULL,
    "review_dt" TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL,
    "notes" TEXT NULL
);
ALTER TABLE
    "review" ADD PRIMARY KEY("review_id");
CREATE TABLE "attribute"(
    "attr_id" BIGINT NOT NULL,
    "attr_key" TEXT NOT NULL,
    "display_name" TEXT NOT NULL,
    "data_type" VARCHAR(255) CHECK
        ("data_type" IN ('bool', 'int', 'decimal', 'text', 'option')) NOT NULL,
    "unit" TEXT NULL,
    "min_value" BIGINT NULL,
    "max_value" BIGINT NULL,
    "applies_to" VARCHAR(255)
    CHECK
        ("applies_to" IN ('restroom', 'review')) NOT NULL
);
ALTER TABLE
    "attribute" ADD PRIMARY KEY("attr_id");
CREATE TABLE "attribute_value"(
    "restroom_id" BIGINT NOT NULL,
    "attr_id" BIGINT NOT NULL,
    "value_bool" BOOLEAN NULL,
    "value_int" INTEGER NULL,
    "value_decimal" DECIMAL(10, 2) NULL,
    "value_text" TEXT NULL,
    "value_option_id" BIGINT NULL,
    "review_id" BIGINT NULL
);
ALTER TABLE
    "attribute_value" ADD PRIMARY KEY("restroom_id", "attr_id");
CREATE TABLE "attribute_option"(
    "option_id" BIGINT NOT NULL,
    "attr_id" BIGINT NOT NULL,
    "value_key" TEXT NOT NULL,
    "display_name" TEXT NOT NULL
);
ALTER TABLE
    "attribute_option" ADD PRIMARY KEY("option_id");
ALTER TABLE
    "attribute_option" ADD CONSTRAINT "attribute_option_attr_id_foreign" FOREIGN KEY("attr_id") REFERENCES "attribute"("attr_id");
ALTER TABLE
    "attribute_value" ADD CONSTRAINT "attribute_value_restroom_id_foreign" FOREIGN KEY("restroom_id") REFERENCES "restroom"("restroom_id");
ALTER TABLE
    "attribute_value" ADD CONSTRAINT "attribute_value_review_id_foreign" FOREIGN KEY("review_id") REFERENCES "review"("review_id");
ALTER TABLE
    "attribute_value" ADD CONSTRAINT "attribute_value_value_option_id_foreign" FOREIGN KEY("value_option_id") REFERENCES "attribute_option"("option_id");
ALTER TABLE
    "review" ADD CONSTRAINT "review_restroom_id_foreign" FOREIGN KEY("restroom_id") REFERENCES "restroom"("restroom_id");
ALTER TABLE
    "attribute_value" ADD CONSTRAINT "attribute_value_attr_id_foreign" FOREIGN KEY ("attr_id") REFERENCES "attribute"("attr_id");
ALTER TABLE
    "review" ADD CONSTRAINT "review_user_id_foreign" FOREIGN KEY("user_id") REFERENCES auth.users("id");