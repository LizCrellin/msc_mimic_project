-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- https://github.com/MIT-LCP/mimic-code
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/demographics/icustay_hourly.sql
--
-- Accessed: 25 July 2026
--
-- Modifications:
-- - Creation of view rather than table
-- - Start time is not 24 hours before first heart rate measurement but 24 hours before actual admission to ICU
-- - Only retain ICU stays of at least 24 hours
-- - Simplification of the generation of a time series from -24 h to +24 hours from admission to the ICU
--
-- TO DO:
-- 
-- -----------------------------------------------------------------------------


DROP VIEW IF EXISTS msc_project.icustay_hourly;

CREATE VIEW msc_project.icustay_hourly AS
/* This query generates a row for every hour the patient is in the ICU. */ /* The hour clock no longer starts 24 hours before the first heart rate measurement, rather starting at time of formal admission to ICU. */ /* this query extracts the cohort and every possible hour they were in the ICU */
WITH all_hours AS (
  SELECT
    ie.stay_id, /* round the intime up to the nearest hour */
    ie.intime,
    CASE
      WHEN DATE_TRUNC('hour', ie.intime) = ie.intime   -- replaced time based on heart rate measurement with icu_intime, official start of icu stay.
      THEN ie.intime
      ELSE DATE_TRUNC('hour', ie.intime) + INTERVAL '1' HOUR
    END AS endtime                                                       -- no creation of an array needed here
  FROM mimiciv_icu.icustays AS ie                                        -- directly using the in and out times from the ICU stays, not a derived version based on heart rate measurements.
  WHERE CEIL(EXTRACT(EPOCH FROM (ie.outtime - ie.intime)) / 3600) >= 24  -- The ICU stay must be for at least 24 hours.
  )
SELECT
    a.stay_id,
    a.intime,                                                            -- retain intime for checks
    hr,                                                                  -- hr is generated as a series at the end
    a.endtime + hr * INTERVAL '1 hour' AS hour_end
FROM all_hours a
CROSS JOIN LATERAL
generate_series(-24, 24) AS hr                                           -- hr is changed to a simple series
ORDER BY stay_id, hr;