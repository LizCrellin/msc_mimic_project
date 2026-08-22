-- -----------------------------------------------------------------------------
-- Purpose:
--- Get counts of patients at each stage of applying inclusion criteria,
--- for an inclusion diagram.
--- This is an adaptation of the original cohort extraction in src/sql/cohort/patients.sql
-- -----------------------------------------------------------------------------


-- Every ICU stay
SELECT 
  COUNT(*) AS n_stays,
  COUNT(DISTINCT subject_id) as n_patients
FROM mimiciv_icu.icustays;

-- Match to hospital admission and individual patient
DROP TABLE IF EXISTS mimiciv_derived.patient_counts; CREATE TABLE mimiciv_derived.patient_counts AS
SELECT
  ie.subject_id,
  ie.hadm_id,
  ie.stay_id as icustay_id, /* patient level factors */
/* calculate the age as anchor_age (60) plus difference between */ /* admit year and the anchor year. */ /* the noqa retains the extra long line so the */ /* convert to postgres bash script works */
  pat.anchor_age + CAST(EXTRACT(YEAR FROM adm.admittime) - EXTRACT(YEAR FROM MAKE_TIMESTAMP(pat.anchor_year, 1, 1, 0, 0, 0)) AS BIGINT) AS admission_age, /* noqa: L016 */
  CASE
    WHEN DENSE_RANK() OVER (PARTITION BY adm.subject_id ORDER BY adm.admittime NULLS FIRST) = 1
    THEN TRUE
    ELSE FALSE
  END AS first_hosp_stay, /* icu level factors */
  ie.intime AS icu_intime,
  ie.outtime AS icu_outtime,
  CASE
    WHEN DENSE_RANK() OVER (PARTITION BY ie.hadm_id ORDER BY ie.intime NULLS FIRST) = 1
    THEN TRUE
    ELSE FALSE
  END AS first_icu_stay
FROM mimiciv_icu.icustays AS ie
INNER JOIN mimiciv_hosp.admissions AS adm
  ON ie.hadm_id = adm.hadm_id
INNER JOIN mimiciv_hosp.patients AS pat
  ON ie.subject_id = pat.subject_id;

SELECT 
  COUNT(*) AS n_stays,
  COUNT(DISTINCT subject_id) as n_patients
FROM mimiciv_derived.patient_counts;

-- admission age >= 18
SELECT 
  COUNT(*) AS n_stays,
  COUNT(DISTINCT subject_id) as n_patients
FROM mimiciv_derived.patient_counts
WHERE admission_age >= 18;

--First ICU admission
SELECT 
  COUNT(*) AS n_stays,
  COUNT(DISTINCT subject_id) as n_patients
FROM mimiciv_derived.patient_counts
WHERE admission_age >= 18
AND first_icu_stay = TRUE
AND first_hosp_stay = TRUE;

-- ICU stay of at least one day
SELECT 
  COUNT(*) AS n_stays,
  COUNT(DISTINCT subject_id) as n_patients
FROM mimiciv_derived.patient_counts
WHERE admission_age >= 18
AND first_icu_stay = TRUE
AND first_hosp_stay = TRUE
AND icu_outtime - icu_intime >= INTERVAL '24' HOUR;  --replaced los_icu >= 1 as the los_icu calculation is rounded, I need exactly 24 hours.