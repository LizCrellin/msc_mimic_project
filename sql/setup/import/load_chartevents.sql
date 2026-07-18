--This script has been adapted from the original MIMIC-IV load_gz.sql script to load individual tables as required.


-----------------------------------------
-- Load data into the MIMIC-IV schemas --
-----------------------------------------

\cd :mimic_data_dir

-- making sure that all tables are empty and correct encoding is defined -utf8- 
SET CLIENT_ENCODING TO 'utf8';

--icu schema
\cd icu

-- Loading the filtered table into the icu schema 
\COPY mimiciv_icu.chartevents
FROM 'chartevents_filtered.csv'
DELIMITER ','
CSV HEADER
NULL '';