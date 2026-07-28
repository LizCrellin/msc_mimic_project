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
    INNER JOIN mimiciv_derived.vitalsign AS v
        ON v.stay_id = ch.stay_id
        AND v.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND v.charttime < ch.hour_end
    GROUP BY ch.stay_id, ch.hr
),
chemistry_hourly AS
(
    SELECT
        ch.stay_id,
        ch.hr,
        avg(c.albumin) AS albumin,
        avg(c.globulin) AS globulin,
        avg(c.total_protein) AS total_protein,
        avg(c.aniongap) as aniongap,
        avg(c.bicarbonate) as bicarbonate,
        avg(c.bun) as bun,
        avg(c.calcium) as calcium,
        avg(c.chloride) as chloride,
        avg(c.creatinine) as creatinine,
        avg(c.glucose) as glucose,
        avg(c.sodium) as sodium,
        avg(c.potassium) as potassium,
        avg(c.magnesium) as magnesium
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.chemistry as c
        ON ch.hadm_id = c.hadm_id
        AND c.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND c.charttime < ch.hour_end
    GROUP BY ch.stay_id, ch.hr
),
gcs_hourly AS
(
    SELECT
        ch.stay_id,
        ch.hr,
        avg(g.gcs) as gcs
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.gcs AS g
        ON ch.stay_id = g.stay_id
        AND g.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND g.charttime < ch.hour_end
    GROUP BY ch.stay_id, ch.hr
),
blood_hourly AS 
(
    SELECT
        ch.stay_id,
        ch.hr,
        avg(hematocrit) as hematocrit,
        avg(hemoglobin) as hemoglobin,
        avg(mch) as mch,
        avg(mchc) as mchc,
        avg(mcv) as mcv,
        avg(platelet) as platelet,
        avg(rbc) as rbc,
        avg(rdw) as rdw,
        avg(rdwsd) as rdwsd,
        avg(wbc) as wbc
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.complete_blood_count as b
        ON ch.hadm_id = b.hadm_id
        AND b.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND b.charttime < ch.hour_end
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
    vh.glucose_vital,
    chh.albumin,
    chh.globulin,
    chh.total_protein,
    chh.aniongap,
    chh.bicarbonate,
    chh.bun,
    chh.calcium,
    chh.chloride,
    chh.creatinine,
    chh.glucose,
    chh.sodium,
    chh.potassium,
    chh.magnesium,
    gh.gcs,
    bh.hematocrit,
    bh.hemoglobin,
    bh.mch,
    bh.mchc,
    bh.mcv,
    bh.platelet,
    bh.rbc,
    bh.rdw,
    bh.rdwsd,
    bh.wbc
FROM cohort_hours as ch
LEFT JOIN vitalsigns_hourly as vh
    ON ch.stay_id = vh.stay_id
    AND ch.hr = vh.hr
LEFT JOIN chemistry_hourly as chh
    ON ch.stay_id = chh.stay_id
    AND ch.hr = chh.hr
LEFT JOIN gcs_hourly as gh
    ON ch.stay_id = gh.stay_id
    AND ch.hr = gh.hr
LEFT JOIN blood_hourly as bh
    ON ch.stay_id = bh.stay_id
    AND ch.hr = bh.hr;