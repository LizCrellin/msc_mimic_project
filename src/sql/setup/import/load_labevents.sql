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

-- making sure that all tables are empty and correct encoding is defined -utf8- 
SET CLIENT_ENCODING TO 'utf8';

-- hosp schema
\cd hosp

-- Loading the filtered table into the hosp schema 
-- Only the retained columns are imported
\COPY mimiciv_hosp.labevents (labevent_id, subject_id, hadm_id, specimen_id, itemid, order_provider_id, charttime, value, valuenum, valueuom, ref_range_lower, ref_range_upper, flag, priority) FROM 'labevents_filtered.csv' DELIMITER ',' CSV HEADER NULL '';