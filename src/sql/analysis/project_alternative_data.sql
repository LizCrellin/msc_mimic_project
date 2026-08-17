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
-- joins can be made on hadm_id as well as stay_id and will still relate to
-- the same stay.
-- Creating a long table which can be pivoted later to avoid having separate 
-- lines of code for the creation of aggregate features for each variable.
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
    SELECT p.subject_id, p.hadm_id, p.icustay_id, p.icu_intime, vl.variable_name, vl.value, vl.charttime
    FROM patients as p
    INNER JOIN vitalsign_long as vl
    ON p.icustay_id = vl.stay_id
    WHERE vl.charttime <= p.icu_intime + INTERVAL '24' HOUR    -- observation must be within first 24 hours of ICU stay
    AND vl.charttime >= p.icu_intime - INTERVAL '24' HOUR      -- getting labs also from 24 h prior to admission, where available
),
chemistry_long AS (
    SELECT hadm_id, charttime, 'albumin' as variable_name, albumin as value
    from mimiciv_derived.chemistry where albumin is not null
    UNION ALL
    SELECT hadm_id, charttime, 'globulin' as variable_name, globulin as value
    from mimiciv_derived.chemistry where globulin is not null
    UNION ALL    
    SELECT hadm_id, charttime, 'total_protein' as variable_name, total_protein as value
    from mimiciv_derived.chemistry where total_protein is not null
    UNION ALL 
    SELECT hadm_id, charttime, 'aniongap' as variable_name, aniongap as value
    from mimiciv_derived.chemistry where aniongap is not null
    UNION ALL
    SELECT hadm_id, charttime, 'bicarbonate' as variable_name, bicarbonate as value
    from mimiciv_derived.chemistry where bicarbonate is not null
    UNION ALL
    SELECT hadm_id, charttime, 'bun' as variable_name, bun as value
    from mimiciv_derived.chemistry where bun is not null
    UNION ALL
    SELECT hadm_id, charttime, 'calcium' as variable_name, calcium as value
    from mimiciv_derived.chemistry where calcium is not null
    UNION ALL
    SELECT hadm_id, charttime, 'chloride' as variable_name, chloride as value
    from mimiciv_derived.chemistry where chloride is not null
    UNION ALL   
    SELECT hadm_id, charttime, 'creatinine' as variable_name, creatinine as value
    from mimiciv_derived.chemistry where creatinine is not null
    UNION ALL
    -- SELECT hadm_id, charttime, 'glucose_lab' as variable_name, glucose as value    # remove glucose as its in the vitals
    -- from mimiciv_derived.chemistry where glucose is not null
    -- UNION ALL
    SELECT hadm_id, charttime, 'sodium' as variable_name, sodium as value
    from mimiciv_derived.chemistry where sodium is not null
    UNION ALL
    SELECT hadm_id, charttime, 'potassium' as variable_name, potassium as value
    from mimiciv_derived.chemistry where potassium is not null
    UNION ALL
    SELECT hadm_id, charttime, 'magnesium' as variable_name, magnesium as value
    from mimiciv_derived.chemistry where magnesium is not null
),
chemistry AS (
    SELECT p.subject_id, p.hadm_id, p.icustay_id, p.icu_intime, cl.variable_name, cl.value, cl.charttime
    FROM patients as p
    INNER JOIN chemistry_long as cl
    ON p.hadm_id = cl.hadm_id
    WHERE cl.charttime <= p.icu_intime + INTERVAL '24' HOUR
    AND cl.charttime >= p.icu_intime - INTERVAL '24' HOUR
), 
gcs_long AS (
    SELECT stay_id, charttime, 'gcs' as variable_name, gcs as value
    from mimiciv_derived.gcs where gcs is not null
),
gcs AS (
    SELECT p.subject_id, p.hadm_id, p.icustay_id, p.icu_intime, gl.variable_name, gl.value, gl.charttime
    FROM patients as p
    INNER JOIN gcs_long as gl
    ON p.icustay_id = gl.stay_id
    WHERE gl.charttime <= p.icu_intime + INTERVAL '24' HOUR
    AND gl.charttime >= p.icu_intime - INTERVAL '24' HOUR
), 
blood_long AS (
    SELECT hadm_id, charttime, 'hematocrit' as variable_name, hematocrit as value
    from mimiciv_derived.complete_blood_count where hematocrit is not null
    UNION ALL
    SELECT hadm_id, charttime, 'hemoglobin' as variable_name, hemoglobin as value
    from mimiciv_derived.complete_blood_count where hemoglobin is not null
    UNION ALL    
    SELECT hadm_id, charttime, 'mch' as variable_name, mch as value
    from mimiciv_derived.complete_blood_count where mch is not null
    UNION ALL
    SELECT hadm_id, charttime, 'mchc' as variable_name, mchc as value
    from mimiciv_derived.complete_blood_count where mchc is not null
    UNION ALL
    SELECT hadm_id, charttime, 'mcv' as variable_name, mcv as value
    from mimiciv_derived.complete_blood_count where mcv is not null
    UNION ALL
    SELECT hadm_id, charttime, 'platelet' as variable_name, platelet as value
    from mimiciv_derived.complete_blood_count where platelet is not null
    UNION ALL
    SELECT hadm_id, charttime, 'rbc' as variable_name, rbc as value
    from mimiciv_derived.complete_blood_count where rbc is not null
    UNION ALL
    SELECT hadm_id, charttime, 'rdw' as variable_name, rdw as value
    from mimiciv_derived.complete_blood_count where rdw is not null
    UNION ALL
    SELECT hadm_id, charttime, 'wbc' as variable_name, wbc as value
    from mimiciv_derived.complete_blood_count where wbc is not null
    UNION ALL
    SELECT hadm_id, charttime, 'rbc' as variable_name, rbc as value
    from mimiciv_derived.complete_blood_count where rbc is not null
),
blood AS (
    SELECT p.subject_id, p.hadm_id, p.icustay_id, p.icu_intime, bl.variable_name, bl.value, bl.charttime
    FROM patients as p
    INNER JOIN blood_long as bl
    ON p.hadm_id = bl.hadm_id
    WHERE bl.charttime <= p.icu_intime + INTERVAL '24' HOUR
    AND bl.charttime >= p.icu_intime - INTERVAL '24' HOUR
)
SELECT
    subject_id,
    hadm_id,
    icustay_id,
    variable_name,
    MIN(value) as value_min,
    MAX(value) as value_max,
    AVG(value) as value_avg,
    STDDEV_SAMP(value) as value_std,
    COUNT(value) as value_count,
    (ARRAY_AGG(value ORDER BY charttime ASC)) [1] AS value_first,
    (ARRAY_AGG(value ORDER BY charttime DESC)) [1] AS value_last,
    EXTRACT(EPOCH FROM (MIN(charttime) - icu_intime)) / 3600 AS value_first_time,
    EXTRACT(EPOCH FROM (MAX(charttime) - icu_intime)) / 3600 AS value_last_time,
    REGR_SLOPE(value, (EXTRACT(EPOCH FROM charttime) / 3600) ) AS value_slope
FROM vitalsign
GROUP BY subject_id, hadm_id, icustay_id, icu_intime, variable_name
ORDER BY icustay_id, variable_name;