-- Create schema
CREATE SCHEMA schedule;

-- Create content table
CREATE TABLE content.notes (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE schedule.timelogs (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    start_time TIMESTAMPTZ NOT NULL,
    end_time   TIMESTAMPTZ,
    note TEXT NOT NULL
    CHECK (end_time IS NULL OR end_time >= start_time)
)

----------
--DROP TABLE content.notes;
--DROP TABLE content.timelogs;