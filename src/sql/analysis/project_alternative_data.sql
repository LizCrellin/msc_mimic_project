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
vitalsign_long AS
(
    SELECT stay_id, charttime, 'heart_rate' as variable_name, heart_rate as value
    from mimiciv_derived.vitalsign where heart_rate is not null
    UNION ALL
    SELECT stay_id, charttime, 'sbp' as variable_name, sbp as value
    from mimiciv_derived.vitalsign where sbp is not null
    UNION ALL
    SELECT stay_id, charttime, 'dbp' as variable_name, dbp as value
    from mimiciv_derived.vitalsign where dbp is not null
    UNION ALL
    SELECT stay_id, charttime, 'mbp' as variable_name, mbp as value
    from mimiciv_derived.vitalsign where mbp is not null
    UNION ALL
    SELECT stay_id, charttime, 'sbp_ni' as variable_name, sbp_ni as value
    from mimiciv_derived.vitalsign where sbp_ni is not null
    UNION ALL       
    SELECT stay_id, charttime, 'dbp_ni' as variable_name, dbp_ni as value
    from mimiciv_derived.vitalsign where dbp_ni is not null
    UNION ALL
    SELECT stay_id, charttime, 'mbp_ni' as variable_name, mbp_ni as value
    from mimiciv_derived.vitalsign where mbp_ni is not null
    UNION ALL
    SELECT stay_id, charttime, 'resp_rate' as variable_name, resp_rate as value
    from mimiciv_derived.vitalsign where resp_rate is not null
    UNION ALL
    SELECT stay_id, charttime, 'temperature' as variable_name, temperature as value
    from mimiciv_derived.vitalsign where temperature is not null
    UNION ALL
    SELECT stay_id, charttime, 'spo2' as variable_name, spo2 as value
    from mimiciv_derived.vitalsign where spo2 is not null
    UNION ALL
    SELECT stay_id, charttime, 'glucose_vital' as variable_name, glucose as value
    from mimiciv_derived.vitalsign where glucose is not null
),
vitalsign AS (
    SELECT p.icustay_id, p.icu_intime, vl.variable_name, vl.value, vl.charttime
    FROM patients as p
    INNER JOIN vitalsign_long as vl
    ON p.icustay_id = vl.stay_id
    WHERE vl.charttime <= p.icu_intime + INTERVAL '24' HOUR    -- observation must be within first 24 hours of ICU stay
    AND vl.charttime >= p.icu_intime - INTERVAL '24' HOUR      -- getting labs also from 24 h prior to admission, where available
),
chemistry_long AS (
    SELECT stay_id, charttime, 'albumin' as variable_name, albumin as value
    from mimiciv_derived.chemistry where albumin is not null
    UNION ALL



        -- avg(c.globulin) AS globulin,
        -- avg(c.total_protein) AS total_protein,
        -- avg(c.aniongap) as aniongap,
        -- avg(c.bicarbonate) as bicarbonate,
        -- avg(c.bun) as bun,
        -- avg(c.calcium) as calcium,
        -- avg(c.chloride) as chloride,
        -- avg(c.creatinine) as creatinine,
        -- avg(c.glucose) as glucose,
        -- avg(c.sodium) as sodium,
        -- avg(c.potassium) as potassium,
        -- avg(c.magnesium) as magnesium
)
-- will be adding and appending the other tables here.
SELECT
    icustay_id
    icu_intime,
    variable_name,
    MIN(value) as value_min,
    MAX(value) as value_max,
    AVG(value) as value_avg,
    STDDEV_SAMP(value) as value_std,
    COUNT(value) as value_count,
    (ARRAY_AGG(value ORDER BY charttime ASC)) [1] AS value_first,
    (ARRAY_AGG(value ORDER BY charttime DESC)) [1] AS value_last,
    EXTRACT(EPOCH FROM (MIN(charttime) - icu_intime)) AS value_first_time,
    EXTRACT(EPOCH FROM (MAX(charttime) - icu_intime)) AS value_last_time,
    REGR_SLOPE(value, EXTRACT(EPOCH FROM charttime)) AS value_slope
FROM vitalsign
GROUP BY icustay_id, icu_intime, variable_name;