-- Create schema
CREATE SCHEMA fixtures AUTHORIZATION admin;

-- Create manufacturer table
CREATE TABLE fixtures.manufacturer (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);


-- Create fixture_type table
CREATE TABLE fixtures.fixture_type (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);


-- Create fixture_model table
CREATE TABLE fixtures.fixture_model (
    id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    manufacturer_id INTEGER NOT NULL 
        REFERENCES fixtures.manufacturer(id)
        ON DELETE RESTRICT,
    fixture_type_id INTEGER NOT NULL
        REFERENCES fixtures.fixture_type(id)
        ON DELETE RESTRICT,

    model_name TEXT NOT NULL,
    short_name TEXT,

    power_peak_amps NUMERIC(5,2),
    usual_dmx_mode TEXT,

    notes TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (manufacturer_id, model_name)
);

CREATE INDEX ON fixtures.fixture_model (manufacturer_id);
CREATE INDEX ON fixtures.fixture_model (fixture_type_id);

-----
DROP TABLE fixtures.fixture_model;
DROP TABLE fixtures.fixture_type;
DROP TABLE fixtures.manufacturer;
