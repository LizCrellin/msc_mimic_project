-- -----------------------------------------------------------------------------
--
-- Drafted: 27 July 2026
--
-- Purpose:
-- Create indexes on the large tables in the MIMIC IV dataset, chart
-- events and lab events.
-- For chart events this will be on stay_id and charttime to allow 
-- for generation of the concept views and subsequent joining to the spine 
-- on time. 
-- For labevents, this will be on itemid, hadm_id and charttime for the same
-- reasons. 
-- I have already preselected itemid on import based on itemid
-- required for the project, so don't expect a large benefit from indexing
-- itemid.
--
-- TO DO:
--
-- -----------------------------------------------------------------------------


CREATE INDEX ix_chartevents_itemid_stay_charttime
    ON mimiciv_icu.chartevents (stay_id, charttime);

CREATE INDEX ix_labevents_itemid_hadm_charttime
    ON mimiciv_hosp.labevents (hadm_id, charttime);