-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- MIT-LCP/mimic-code: MIMIC Code v2.2.1
-- https://doi.org/10.5281/zenodo.6818823
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/medication/milrinone.sql
--
-- Accessed: 24 July 2026
--
-- Modifications:
-- - Removed rate and amount.
--
-- TO DO:
-- - can simplify further?
--
-- -----------------------------------------------------------------------------



DROP TABLE IF EXISTS mimiciv_derived.milrinone; CREATE TABLE mimiciv_derived.milrinone AS
/* This query extracts dose+durations of milrinone administration */ /* Local hospital dosage guidance: 0.5 mcg/kg/min (usual) */
SELECT
  stay_id,
  linkorderid, /* all rows in mcg/kg/min */
  --rate AS vaso_rate,
  --amount AS vaso_amount,
  starttime,
  endtime
FROM mimiciv_icu.inputevents
WHERE
  itemid = 221986 /* milrinone */