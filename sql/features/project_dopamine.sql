-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- https://github.com/MIT-LCP/mimic-code
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/medication/dopamine.sql
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


DROP TABLE IF EXISTS mimiciv_derived.dopamine; CREATE TABLE mimiciv_derived.dopamine AS
/* This query extracts dose+durations of dopamine administration */ /* Local hospital dosage guidance: 2 mcg/kg/min (low) - 10 mcg/kg/min (high) */
SELECT
  stay_id,
  linkorderid, /* all rows in mcg/kg/min */
  --rate AS vaso_rate,
  --amount AS vaso_amount,
  starttime,
  endtime
FROM mimiciv_icu.inputevents
WHERE
  itemid = 221662 /* dopamine */