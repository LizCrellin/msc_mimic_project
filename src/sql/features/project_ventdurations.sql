-- -----------------------------------------------------------------------------
-- Based on the mimic-iv-aline-study:
-- https://github.com/alistairewj/mimic-iv-aline-study/
--
-- Original file:
-- sql/ventdurations.sql
--
-- Accessed: 25 July 2026
--
-- Modifications:
-- - Creation of view 
-- - Added ventilator mode (Hamilton)
-- - Dropped duration, keeping only start and end times
--
-- TO DO:
--  Develop to generate on and off times for mechanical ventilation
--
-- -----------------------------------------------------------------------------


-- -- explore the data
-- with ve as 
-- (
-- select stay_id, charttime
--     , LAG(charttime, 1) OVER (partition by stay_id order by charttime) AS charttime_lag
--     , itemid
--     , value

--     from mimiciv_icu.chartevents
--     WHERE itemid IN (
--         223849,  -- ventilator mode
--         229314   -- ventilator mode Hamilton
--     )
-- )
-- SELECT itemid, value, COUNT(*) as COUNT
-- FROM ve
-- GROUP BY itemid, value;


DROP VIEW IF EXISTS msc_project.ventdurations;
CREATE VIEW msc_project.ventdurations AS

with vc AS
(
    select stay_id, charttime
    , LAG(charttime, 1) OVER (partition by stay_id order by charttime) AS charttime_lag

    from mimiciv_icu.chartevents
    WHERE itemid IN (
        223849,  -- ventilator mode
        229314   -- ventilator mode Hamilton     -- addition compared to original script
    )
    AND value != 'Standby'
)
, vd1 as
(
  SELECT
    stay_id,
    charttime_lag,
    charttime,
    -- Split events if they occur more than 8 hours apart
    CASE
        WHEN charttime > charttime_lag + INTERVAL '8 hours'
        THEN 1
        ELSE 0
    END AS newvent
FROM vc
)
, vd2 as
(
  select vd1.*
  -- create a cumulative sum of the instances of new ventilation
  -- this results in a monotonic integer assigned to each instance of ventilation
  , SUM( newvent ) OVER ( partition by stay_id order by charttime ) as ventnum
  --- now we convert CHARTTIME of ventilator settings into durations
  from vd1
)
-- create the durations for each mechanical ventilation instance
select stay_id
  -- regenerate ventnum so it's sequential
  , ROW_NUMBER() over (partition by stay_id order by ventnum) as vent_seq
  , min(charttime) as starttime
  , max(charttime) as endtime
  --, DATETIME_DIFF(max(charttime), min(charttime), MINUTE)/60 AS duration_hours
from vd2
group by stay_id, vd2.ventnum
having min(charttime) != max(charttime)