-- -----------------------------------------------------------------------------
--
-- Drafted: 27 July 2026
--
-- Purpose:
-- Create indexes on the large tables in the MIMIC IV dataset, chart
-- events and lab events.
-- For chart events this will be a composite index on (itemid, stay_id, charttime) 
-- as processing starts with filtering on itemid for the features but also has
-- GROUP BY on stay_id and charttime and later, joins to the spine based on time.
-- For labevents, this will be on itemid, hadm_id and charttime for the same
-- reasons. 
--
-- TO DO:
--
-- -----------------------------------------------------------------------------


CREATE INDEX ix_chartevents_itemid_stay_charttime
    ON mimiciv_icu.chartevents (itemid, stay_id, charttime);

CREATE INDEX ix_labevents_itemid_hadm_charttime
    ON mimiciv_hosp.labevents (itemid, hadm_id, charttime);