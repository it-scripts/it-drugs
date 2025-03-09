-- Install the drug_plants table
CREATE TABLE IF NOT EXISTS drug_plants (
    id VARCHAR(11) NOT NULL, PRIMARY KEY(id),
    owner LONGTEXT DEFAULT NULL,
    coords LONGTEXT NOT NULL,
    dimension INT(11) NOT NULL,
    time INT(255) NOT NULL,
    type VARCHAR(100) NOT NULL,
    health DOUBLE NOT NULL DEFAULT 100,
    fertilizer DOUBLE NOT NULL DEFAULT 0,
    water DOUBLE NOT NULL DEFAULT 0,
    growtime INT(11) NOT NULL
);

-- Install the drug_processing table
CREATE TABLE IF NOT EXISTS drug_processing (
    id VARCHAR(11) NOT NULL, PRIMARY KEY(id),
    coords LONGTEXT NOT NULL,
    rotation DOUBLE NOT NULL,
    dimension INT(11) NOT NULL,
    owner LONGTEXT NOT NULL,
    type VARCHAR(100) NOT NULL
);
