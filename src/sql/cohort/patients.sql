-- -----------------------------------------------------------------------------
-- Based on the official MIMIC Code repository:
-- https://github.com/MIT-LCP/mimic-code
--
-- Original file:
-- mimic-iv/buildmimic/concepts_postgres/demographics/icustay_detail.sql
--
-- Accessed: 13 July 2026
--
-- Modifications compared to the original file:
-- - Creation of view rather than tables
-- - Limits the output to ICU stays that meet inclusion criteria for the project:
-- - - First ICU stay for each patient
-- - - ICU stay of at least 1 day
-- - - Patient age at admission >= 18
-- - - Added admission type and admission location
-- - Does not retain flags for first hospital or ICU stay_id or stay sequence
--
-- TO DO:
-- - could add checks e.g. that icu intime is after hosp admission 
--
-- -----------------------------------------------------------------------------

DROP VIEW IF EXISTS msc_project.allpatients CASCADE;

CREATE VIEW msc_project.allpatients AS

WITH allpatients AS
(
SELECT
  ie.subject_id,
  ie.hadm_id,
  ie.stay_id as icustay_id, /* patient level factors */
  pat.gender,
  pat.dod, /* hospital level factors */
  adm.admittime,
  adm.dischtime,
  adm.admission_type,
  adm.admission_location,
  (CAST(adm.dischtime AS DATE) - CAST(adm.admittime AS DATE)) AS los_hospital, /* calculate the age as anchor_age (60) plus difference between */ /* admit year and the anchor year. */ /* the noqa retains the extra long line so the */ /* convert to postgres bash script works */
  pat.anchor_age + CAST(EXTRACT(YEAR FROM adm.admittime) - EXTRACT(YEAR FROM MAKE_TIMESTAMP(pat.anchor_year, 1, 1, 0, 0, 0)) AS BIGINT) AS admission_age, /* noqa: L016 */
  adm.race,
  adm.hospital_expire_flag,
  DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime NULLS FIRST) AS hospstay_seq,
  CASE
    WHEN DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime NULLS FIRST) = 1
    THEN TRUE
    ELSE FALSE
  END AS first_hosp_stay, /* icu level factors */
  ie.intime AS icu_intime,
  ie.outtime AS icu_outtime,
  ROUND(
    CAST(CAST(CAST(EXTRACT(EPOCH FROM DATE_TRUNC('hour', ie.outtime) - DATE_TRUNC('hour', ie.intime)) / 3600 AS BIGINT) AS DOUBLE PRECISION) / 24.0 AS DECIMAL(38, 9)),
    2
  ) AS los_icu,
  DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime NULLS FIRST) AS icustay_seq, /* first ICU stay *for the current hospitalization* */
  CASE
    WHEN DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime NULLS FIRST) = 1
    THEN TRUE
    ELSE FALSE
  END AS first_icu_stay
FROM mimiciv_icu.icustays AS ie
INNER JOIN mimiciv_hosp.admissions AS adm
  ON ie.hadm_id = adm.hadm_id
INNER JOIN mimiciv_hosp.patients AS pat
  ON ie.subject_id = pat.subject_id
)
SELECT
  subject_id,
  hadm_id,
  icustay_id,
  gender,
  dod,
  admittime,
  dischtime,
  admission_type,
  admission_location,
  admission_age,
  race,
  hospital_expire_flag,
  icu_intime,             
  icu_outtime,
  los_icu
FROM allpatients
WHERE first_icu_stay = TRUE
AND first_hosp_stay = TRUE
AND los_icu >= 1
AND admission_age >= 18;