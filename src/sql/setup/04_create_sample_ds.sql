-- -----------------------------------------------------------------------------
--
-- Drafted: 2 August 2026
--
-- Purpose:
-- Create a random sample of 50 ICU stays, and extracts data relevant to these
-- stays from each of the MIMIC tables I'm using for this project.
-- This sample extract will be used for local testing.
--
-- TO DO:
--
-- -----------------------------------------------------------------------------

SELECT setseed(0.33);

DROP TABLE IF EXISTS msc_project.sample_stays;
CREATE TABLE msc_project.sample_stays AS
SELECT
  icustay_id,
  hadm_id,
  subject_id
FROM msc_project.allpatients
ORDER BY RANDOM()
LIMIT 50;


-- ICU schema
DROP TABLE IF EXISTS msc_project.sample_icustays;
CREATE TABLE msc_project.sample_icustays AS
SELECT icu.*
FROM mimiciv_icu.icustays AS icu
INNER JOIN msc_project.sample_stays AS s
  ON icu.stay_id = s.icustay_id;

DROP TABLE IF EXISTS msc_project.sample_chartevents;
CREATE TABLE msc_project.sample_chartevents AS
SELECT ce.*
FROM mimiciv_icu.chartevents AS ce
INNER JOIN msc_project.sample_stays AS s
  ON ce.stay_id = s.icustay_id;

DROP TABLE IF EXISTS msc_project.sample_inputevents;
CREATE TABLE msc_project.sample_inputevents AS
SELECT ie.*
FROM mimiciv_icu.inputevents AS ie
INNER JOIN msc_project.sample_stays AS s
  ON ie.stay_id = s.icustay_id;

-- hosp schema (no stay_id, so join via hadm_id / subject_id)

DROP TABLE IF EXISTS msc_project.sample_admissions;
CREATE TABLE msc_project.sample_admissions AS
SELECT adm.*
FROM mimiciv_hosp.admissions AS adm
INNER JOIN msc_project.sample_stays AS s
  ON adm.hadm_id = s.hadm_id;

DROP TABLE IF EXISTS msc_project.sample_patients;
CREATE TABLE msc_project.sample_patients AS
SELECT pat.*
FROM mimiciv_hosp.patients AS pat
INNER JOIN (
  SELECT DISTINCT subject_id FROM msc_project.sample_stays
) AS s
  ON pat.subject_id = s.subject_id;

DROP TABLE IF EXISTS msc_project.sample_labevents;
CREATE TABLE msc_project.sample_labevents AS
SELECT le.*
FROM mimiciv_hosp.labevents AS le
INNER JOIN msc_project.sample_stays AS s
  ON le.hadm_id = s.hadm_id;


-- key derived tables

DROP TABLE IF EXISTS msc_project.sample_hourly_data;
CREATE TABLE msc_project.sample_hourly_data AS
SELECT hd.*
FROM msc_project.hourly_data AS hd
INNER JOIN msc_project.sample_stays AS s
  ON hd.icustay_id = s.icustay_id;

DROP TABLE IF EXISTS msc_project.sample_allpatients;
CREATE TABLE msc_project.sample_allpatients AS
SELECT p.*
FROM msc_project.allpatients AS p
INNER JOIN msc_project.sample_stays AS s
  ON p.icustay_id = s.icustay_id;

DROP TABLE IF EXISTS msc_project.sample_alternative_data;
CREATE TABLE msc_project.sample_alternative_data AS
SELECT ad.*
FROM msc_project.alternative_data AS ad
INNER JOIN msc_project.sample_stays AS s
  ON ad.icustay_id = s.icustay_id;
