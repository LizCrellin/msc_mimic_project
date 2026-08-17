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
-- Naming of icustay_id and hour variable have been updated to match up 
-- with publicly available pipelines for ease of adapting their code. Specifically
-- this one: https://github.com/MLforHealth/MIMIC_Extract/tree/master
--
-- TO DO:
-- Later: consider adding intervention events (ventilation, vasoactive agents)
--
-- -----------------------------------------------------------------------------


DROP VIEW IF EXISTS msc_project.hourly_data;

CREATE VIEW msc_project.hourly_data AS

with cohort_hours AS
(
    SELECT
        p.icustay_id,
        p.subject_id,
        p.hadm_id,
        h.hours_in,
        h.hour_end
    FROM msc_project.icustay_hourly AS h
    INNER JOIN msc_project.allpatients AS p
        ON h.icustay_id = p.icustay_id
),
vitalsigns_hourly AS
(
    SELECT
        ch.icustay_id,
        ch.hours_in,
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
        ON v.stay_id = ch.icustay_id
        AND v.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND v.charttime <= ch.hour_end
    GROUP BY ch.icustay_id, ch.hours_in
),
chemistry_hourly AS
(
    SELECT
        ch.icustay_id,
        ch.hours_in,
        avg(c.albumin) AS albumin,
        avg(c.globulin) AS globulin,
        avg(c.total_protein) AS total_protein,
        avg(c.aniongap) as aniongap,
        avg(c.bicarbonate) as bicarbonate,
        avg(c.bun) as bun,
        avg(c.calcium) as calcium,
        avg(c.chloride) as chloride,
        avg(c.creatinine) as creatinine,
        --avg(c.glucose) as glucose,   # remove glucose as its included in vitals
        avg(c.sodium) as sodium,
        avg(c.potassium) as potassium,
        avg(c.magnesium) as magnesium
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.chemistry as c
        ON ch.hadm_id = c.hadm_id
        AND c.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND c.charttime <= ch.hour_end
    GROUP BY ch.icustay_id, ch.hours_in
),
gcs_hourly AS
(
    SELECT
        ch.icustay_id,
        ch.hours_in,
        avg(g.gcs) as gcs
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.gcs AS g
        ON ch.icustay_id = g.stay_id
        AND g.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND g.charttime <= ch.hour_end
    GROUP BY ch.icustay_id, ch.hours_in
),
blood_hourly AS 
(
    SELECT
        ch.icustay_id,
        ch.hours_in,
        avg(hematocrit) as hematocrit,
        avg(hemoglobin) as hemoglobin,
        avg(mch) as mch,
        avg(mchc) as mchc,
        avg(mcv) as mcv,
        avg(platelet) as platelet,
        avg(rbc) as rbc,
        avg(rdw) as rdw,
        --avg(rdwsd) as rdwsd,
        avg(wbc) as wbc
    FROM cohort_hours as ch
    INNER JOIN mimiciv_derived.complete_blood_count as b
        ON ch.hadm_id = b.hadm_id
        AND b.charttime > ch.hour_end - INTERVAL '1' HOUR
        AND b.charttime <= ch.hour_end
    GROUP BY ch.icustay_id, ch.hours_in
)
SELECT
    ch.subject_id,
    ch.hadm_id,
    ch.icustay_id,
    ch.hours_in,
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
    --chh.glucose,
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
    --bh.rdwsd,
    bh.wbc
FROM cohort_hours as ch
LEFT JOIN vitalsigns_hourly as vh
    ON ch.icustay_id = vh.icustay_id
    AND ch.hours_in = vh.hours_in
LEFT JOIN chemistry_hourly as chh
    ON ch.icustay_id = chh.icustay_id
    AND ch.hours_in = chh.hours_in
LEFT JOIN gcs_hourly as gh
    ON ch.icustay_id = gh.icustay_id
    AND ch.hours_in = gh.hours_in
LEFT JOIN blood_hourly as bh
    ON ch.icustay_id = bh.icustay_id
    AND ch.hours_in = bh.hours_in
ORDER BY ch.icustay_id, ch.hours_in;