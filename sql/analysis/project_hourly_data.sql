-- -----------------------------------------------------------------------------
--
-- Drafted: 27 July 2026
--
-- Purpose:
-- Restricting to the eligible cohort defined in msc_project.allpatients. 
-- Joining vital signs to the hourly time 
-- series spine (msc_project.icustay_hourly), with values falling in hourly
-- buckets.
-- Where there are more than one value within an hour, these are averaged.
-- All stays are first ICU stays within first hospital stays, therefore
-- joins can be made on hadm_id as well as stay_id and will stil relate to
-- the same stay.
--
-- TO DO:
-- Addition of GCS (also from ICU stay and linked on stay id), and
-- lab data and bloods (from hosp table and linked on hadm id).
-- Later: consider adding intervention events.
--
-- -----------------------------------------------------------------------------


DROP VIEW IF EXISTS msc_project.hourly_data;

CREATE VIEW msc_project.hourly_data AS

with cohort_hours AS
(
    SELECT
        p.stay_id,
        p.hadm_id,
        h.hr,
        h.hour_end
    FROM msc_project.icustay_hourly AS h
    INNER JOIN msc_project.allpatients AS p
        ON h.stay_id = p.stay_id
),
vitalsigns_hourly AS
(
    SELECT
        ch.stay_id,
        ch.hr,
        AVG(v.heart_rate) AS heart_rate,
        AVG(v.sbp) AS sbp,
        AVG(v.dbp) AS dbp,
        AVG(v.mbp) AS mbp,
        AVG(v.sbp_ni) AS sbp_ni,
        AVG(v.dbp_ni) AS dbp_ni,
        AVG(v.mbp_ni) AS mbp_ni,
        AVG(v.resp_rate) AS resp_rate,
        AVG(v.temperature) AS temperature,
        AVG(v.spo2) AS spo2,
        AVG(v.glucose) AS glucose_vital
    FROM cohort_hours as ch
    INNER JOIN msc_project.vitalsign AS v
        ON v.stay_id = ch.stay_id
        AND v.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND v.charttime < ch.hour_end
    GROUP BY ch.stay_id, ch.hr
)
SELECT
    ch.stay_id,
    ch.hr,
    ch.hour_end,
    vh.heart_rate,
    vh.sbp,
    vh.dbp,
    vh.mbp,
    vh.sbp_ni,
    vh.dbp_ni,
    vh.mbp_ni,
    vh.temperature,
    vh.spo2,
    vh.glucose_vital
FROM cohort_hours as ch
LEFT JOIN vitalsigns_hourly as vh
    ON ch.stay_id = vh.stay_id
    AND ch.hr = vh.hr;