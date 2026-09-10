-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- MIT-LCP/mimic-code: MIMIC Code v2.2.1
-- https://doi.org/10.5281/zenodo.6818823
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/medication/dobutamine.sql
--
-- Accessed: 24 July 2026
--
-- Modifications:
-- - Removed rate and amount.
--
-- TO DO:
-- - can simplify as only need start and end times I think
--
-- -----------------------------------------------------------------------------


DROP TABLE IF EXISTS mimiciv_derived.dobutamine; CREATE TABLE mimiciv_derived.dobutamine AS
/* This query extracts dose+durations of dobutamine administration */ /* Local hospital dosage guidance: 2 mcg/kg/min (low) - 40 mcg/kg/min (max) */
SELECT
  stay_id,
  linkorderid, /* all rows in mcg/kg/min */
  --rate AS vaso_rate,
  --amount AS vaso_amount,
  starttime,
  endtime
FROM mimiciv_icu.inputevents
WHERE
  itemid = 221653 /* dobutamine */