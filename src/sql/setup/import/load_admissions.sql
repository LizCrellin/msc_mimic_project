-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- MIT-LCP/mimic-code: MIMIC Code v2.2.1
-- https://doi.org/10.5281/zenodo.6818823
--
-- Original file:
-- mimic-iv/buildmimic/postgres/load_gz.sql
--
--
-- Modifications:
-- - Adapted to load individual tables as required, since minimal data is to be
-- - loaded to the database for this project, to minimise the storage requirement.
-- - No other changes
-- -----------------------------------------------------------------------------



-----------------------------------------
-- Load data into the MIMIC-IV schemas --
-----------------------------------------

\cd :mimic_data_dir

-- making sure that all tables are emtpy and correct encoding is defined -utf8- 
SET CLIENT_ENCODING TO 'utf8';

-- hosp schema
\cd hosp

\COPY mimiciv_hosp.admissions FROM PROGRAM 'gzip -dc admissions.csv.gz' DELIMITER ',' CSV HEADER NULL '';
