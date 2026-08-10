--This script has been adapted from the original MIMIC-IV load_gz.sql script to load individual tables as required.


-----------------------------------------
-- Load data into the MIMIC-IV schemas --
-----------------------------------------

\cd :mimic_data_dir

-- making sure that all tables are emtpy and correct encoding is defined -utf8- 
SET CLIENT_ENCODING TO 'utf8';

-- hosp schema
\cd hosp

\COPY mimiciv_hosp.patients FROM PROGRAM 'gzip -dc patients.csv.gz' DELIMITER ',' CSV HEADER NULL '';
