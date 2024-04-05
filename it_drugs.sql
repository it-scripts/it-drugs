-- Tabelle drug_plants
CREATE TABLE IF NOT EXISTS drug_plants (
    id INT(11) NOT NULL AUTO_INCREMENT,
    coords LONGTEXT NOT NULL CHECK (JSON_VALID(coords)),
    time INT(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    fertilizer DOUBLE NOT NULL,
    water DOUBLE NOT NULL,
    growtime INT(11) NOT NULL,
    PRIMARY KEY (id)
);

-- Tabelle drug_processing
CREATE TABLE IF NOT EXISTS drug_processing (
    id INT(11) NOT NULL AUTO_INCREMENT,
    coords LONGTEXT NOT NULL CHECK (JSON_VALID(coords)),
    rotation DOUBLE NOT NULL,
    type VARCHAR(100) NOT NULL,
    PRIMARY KEY (id)
);