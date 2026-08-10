--This script has been adapted from the original MIMIC-IV load_gz.sql script to load individual tables as required.


-----------------------------------------
-- Load data into the MIMIC-IV schemas --
-----------------------------------------

\cd :mimic_data_dir

-- making sure that all tables are empty and correct encoding is defined -utf8- 
SET CLIENT_ENCODING TO 'utf8';

-- hosp schema
\cd hosp

-- Loading the filtered table into the hosp schema 
-- Only the retained columns are imported
\COPY mimiciv_hosp.labevents (labevent_id, subject_id, hadm_id, specimen_id, itemid, order_provider_id, charttime, value, valuenum, valueuom, ref_range_lower, ref_range_upper, flag, priority) FROM 'labevents_filtered.csv' DELIMITER ',' CSV HEADER NULL '';