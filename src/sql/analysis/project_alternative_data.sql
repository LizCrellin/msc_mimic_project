-- -----------------------------------------------------------------------------
--
-- Drafted: 17 August 2026
--
-- Purpose:
-- Restricting to the eligible cohort defined in msc_project.allpatients. 
-- Restricting to the 24 hours before and after ICU admission
-- Joining the different concepts together and creating aggregate variables:
----- First observation
----- Last observation
----- Time of first observation
----- Time of last observation
----- Minimum
----- Maximum
----- Mean
----- Standard deviation
----- Number of observations
----- Slope (but review this - avoid if it can be derived from others of these)
--
-- All stays are first ICU stays within first hospital stays, therefore
-- joins can be made on hadm_id as well as stay_id and will stil relate to
-- the same stay.
-- Naming of icustay_id and hour variable have been updated to match up 
-- with publicly available pipelines for ease of adapting their code. Specifically
-- this one: https://github.com/MLforHealth/MIMIC_Extract/tree/master
--
-- TO DO:
-- Later: consider adding intervention events (ventilation, vasoactive agents)
--
-- -----------------------------------------------------------------------------


DROP VIEW IF EXISTS msc_project.alternative_data;

CREATE VIEW msc_project.alternative_data AS

with patients AS
(
    SELECT
        p.icustay_id,
        p.subject_id,
        p.hadm_id,
        p.icu_intime
    FROM msc_project.allpatients AS p
    WHERE p.icu_outtime - p.icu_intime >= INTERVAL '24' HOUR   -- stay must be at least 24 hours
),
vitalsigns_agg AS
(
    SELECT
        p.icustay_id,
        -- Min:
        MIN(v.heart_rate) AS heart_rate_min,
        MIN(v.sbp) AS sbp_min,
        MIN(v.dbp) AS dbp_min,
        MIN(v.mbp) AS mbp_min,
        MIN(v.sbp_ni) AS sbp_ni_min,
        MIN(v.dbp_ni) AS dbp_ni_min,
        MIN(v.mbp_ni) AS mbp_ni_min,
        MIN(v.resp_rate) AS resp_rate_min,
        MIN(v.temperature) AS temperature_min,
        MIN(v.spo2) AS spo2_min,
        MIN(v.glucose) AS glucose_vital_min,
        -- Max:
        MAX(v.heart_rate) AS heart_rate_max,
        MAX(v.sbp) AS sbp_max,
        MAX(v.dbp) AS dbp_max,
        MAX(v.mbp) AS mbp_max,
        MAX(v.sbp_ni) AS sbp_ni_max,
        MAX(v.dbp_ni) AS dbp_ni_max,
        MAX(v.mbp_ni) AS mbp_ni_max,
        MAX(v.resp_rate) AS resp_rate_max,
        MAX(v.temperature) AS temperature_max,
        MAX(v.spo2) AS spo2_max,
        MAX(v.glucose) AS glucose_vital_max,
        -- Means:
        AVG(v.heart_rate) AS heart_rate_avg,
        AVG(v.sbp) AS sbp_avg,
        AVG(v.dbp) AS dbp_avg,
        AVG(v.mbp) AS mbp_avg,
        AVG(v.sbp_ni) AS sbp_ni_avg,
        AVG(v.dbp_ni) AS dbp_ni_avg,
        AVG(v.mbp_ni) AS mbp_ni_avg,
        AVG(v.resp_rate) AS resp_rate_avg,
        AVG(v.temperature) AS temperature_avg,
        AVG(v.spo2) AS spo2_avg,
        AVG(v.glucose) AS glucose_vital_avg,
        -- Std:
        STDDEV_SAMP(v.heart_rate) AS heart_rate_std,
        STDDEV_SAMP(v.sbp) AS sbp_std,
        STDDEV_SAMP(v.dbp) AS dbp_std,
        STDDEV_SAMP(v.mbp) AS mbp_std,
        STDDEV_SAMP(v.sbp_ni) AS sbp_ni_std,
        STDDEV_SAMP(v.dbp_ni) AS dbp_ni_std,
        STDDEV_SAMP(v.mbp_ni) AS mbp_ni_std,
        STDDEV_SAMP(v.resp_rate) AS resp_rate_std,
        STDDEV_SAMP(v.temperature) AS temperature_std,
        STDDEV_SAMP(v.spo2) AS spo2_std,
        STDDEV_SAMP(v.glucose) AS glucose_vital_std,
        --number of observations
        COUNT(v.heart_rate) AS heart_rate_count,
        COUNT(v.sbp) AS sbp_count,
        COUNT(v.dbp) AS dbp_count,
        COUNT(v.mbp) AS mbp_count,
        COUNT(v.sbp_ni) AS sbp_ni_count,
        COUNT(v.dbp_ni) AS dbp_ni_count,
        COUNT(v.mbp_ni) AS mbp_ni_count,
        COUNT(v.resp_rate) AS resp_rate_count,
        COUNT(v.temperature) AS temperature_count,
        COUNT(v.spo2) AS spo2_count,
        COUNT(v.glucose) AS glucose_vital_count
        --First value
        (ARRAY_AGG(v.heart_rate ORDER BY v.charttime ASC))[1] AS heart_rate_first,
        --Last value
        (ARRAY_AGG(v.heart_rate ORDER BY v.charttime DESC))[1] AS heart_rate_first,
    FROM patients as p
    INNER JOIN mimiciv_derived.vitalsign AS v
        ON v.stay_id = p.icustay_id
    WHERE v.charttime <= p.icu_intime + INTERVAL '24' HOUR    -- observation must be within first 24 hours of ICU stay
    AND v.charttime >= p.icu_intime - INTERVAL '24' HOUR      -- getting labs also from 24 h prior to admission, where available
    GROUP BY p.icustay_id
),
--- more tables to be added

SELECT
    p.subject_id,
    p.hadm_id,
    p.icustay_id,
    p.icu_intime,
    va.heart_rate_min,
    va.sbp_min,
    va.dbp_min,
    va.mbp_min,
    va.sbp_ni_min,
    va.dbp_ni_min,
    va.mbp_ni_min,
    va.resp_rate_min,
    va.temperature_min,
    va.spo2_min,
    va.glucose_vital_min,
    va.heart_rate_max,
    va.sbp_max,
    va.dbp_max,
    va.mbp_max,
    va.sbp_ni_max,
    va.dbp_ni_max,
    va.mbp_ni_max,
    va.resp_rate_max,
    va.temperature_max,
    va.spo2_max,
    va.glucose_vital_max,
    va.heart_rate_avg,
    va.sbp_avg,
    va.dbp_avg,
    va.mbp_avg,
    va.sbp_ni_avg,
    va.dbp_ni_avg,
    va.mbp_ni_avg,
    va.resp_rate_avg,
    va.temperature_avg,
    va.spo2_avg,
    va.glucose_vital_avg,
    va.heart_rate_std,
    va.sbp_std,
    va.dbp_std,
    va.mbp_std,
    va.sbp_ni_std,
    va.dbp_ni_std,
    va.mbp_ni_std,
    va.resp_rate_std,
    va.temperature_std,
    va.spo2_std,
    va.glucose_vital_std,
    va.heart_rate_count,
    va.sbp_count,
    va.dbp_count,
    va.mbp_count,
    va.sbp_ni_count,
    va.dbp_ni_count,
    va.mbp_ni_count,
    va.resp_rate_count,
    va.temperature_count,
    va.spo2_count,
    va.glucose_vital_count
FROM patients as p
LEFT JOIN vitalsigns_agg as va
    ON p.icustay_id = va.icustay_id
