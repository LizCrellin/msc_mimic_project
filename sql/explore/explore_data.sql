select * from msc_project.allpatients LIMIT 10;
select * from msc_project.first_icu_stays LIMIT 10;
select * from msc_project.icustay_hourly LIMIT 100;

select count(*) from mimiciv_icu.chartevents;


SELECT current_database();

-- count rows
select count(*) as icustays
from msc_project.allpatients;

--count first icu stays per admission
select count(*) as first_icu_stays
from msc_project.allpatients
where first_icu_stay = TRUE;

--count first icu stays per patient
select count(*) as first_icu_stays
from msc_project.allpatients
where first_icu_stay = TRUE and first_hosp_stay = TRUE;

-- count icustay at least 1 day
select count(*) as icustays_1_day
from msc_project.allpatients
where los_icu >= 1;

--count first icu stays per patient at least 1 day
select count(*) as icustays_1_day
from msc_project.allpatients
where los_icu >= 1
and first_icu_stay = TRUE
and first_hosp_stay = TRUE;

--count first icu stays at least 1 day and age 18 or over
select count(*) as icustays_1_day
from msc_project.allpatients
where los_icu >= 1
and first_icu_stay = TRUE
and first_hosp_stay = TRUE
and admission_age >= 18;

--look at admisson age on its own
select count(*) as icustays_1_day
from msc_project.allpatients
where admission_age >= 18;
--looks like admission age has already been restricted to 18 or over - this is because only adults are in the icustays table.

--distribution of LOS?
select los_icu, count(*) over() as cnt 
from msc_project.allpatients
order by los_icu;

select avg(los_icu) as avg_los_icu from msc_project.allpatients;
select avg(los_icu) as avg_los_icu from msc_project.allpatients where los_icu >= 1;

--how many have zero LOS?
select count(*) as zero_los_icu from msc_project.allpatients where los_icu = 0;
--only 49 - not significant
--how many have <1 day LOS?
select count(*) as less_than_1_day_los_icu from msc_project.allpatients where los_icu < 1;

--icu stays:
select * from msc_project.first_icu_stays LIMIT 10;

select count(*) as firsticustays
from msc_project.first_icu_stays;


--look at labitems table
SELECT itemid, label
FROM mimiciv_hosp.d_labitems
ORDER BY label;

--look at items table (links to chartevents, inputevents etc.)
SELECT itemid, label
FROM mimiciv_icu.d_items
ORDER BY label;

--investigate this code for RDW SD:
SELECT itemid, label
FROM mimiciv_hosp.d_labitems
WHERE itemid = 52159;

SELECT itemid, label
FROM mimiciv_hosp.d_labitems
WHERE LOWER(label) LIKE '%rdw%';


--look at view for vital signs
EXPLAIN(ANALYZE)
select * from msc_project.vitalsign LIMIT 20;
select count(*) as vitalsigncount
from msc_project.vitalsign;   -- 13,519,533

--look at view for lab events
select * from msc_project.chemistry LIMIT 20;
select count(*) from msc_project.chemistry;   -- 4,985,065

--look at view for complete blood count
select * from msc_project.complete_blood_count LIMIT 20;
select count(*) from msc_project.complete_blood_count;   --	4,377,900

--look at view for gcs
select * from msc_project.gcs LIMIT 20;
select count(*) from msc_project.gcs;  -- 2,217,787

--look at view for vasoactive agents
select * from msc_project.vasoactive_agent LIMIT 20;

--look at view for ventilation times
select * from msc_project.ventdurations LIMIT 20;


-------------
--look at project hourly data with vital signs added:
EXPLAIN(ANALYZE)
select * from msc_project.hourly_data LIMIT 20;
--select * from msc_project.hourly_data --cancelled this as took too long.
--where stay_id = 30000213;


----------------
-- look at full project hourly data
select * from msc_project.hourly_data LIMIT 20; --started 22.17. finished 22.21.
select * from msc_project.hourly_data LIMIT 50; --started 08.16. completed in 3 min 16 s.

