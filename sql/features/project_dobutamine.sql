-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- https://github.com/MIT-LCP/mimic-code
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/medication/dobutamine.sql
--
-- Accessed: 24 July 2026
--
-- Modifications:
-- - Creation of views rather than tables
-- - Removed rate and amount.
--
-- TO DO:
-- - can simplify further?
--
-- -----------------------------------------------------------------------------



DROP VIEW msc_project.dobutamine;
CREATE VIEW msc_project.dobutamine AS
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