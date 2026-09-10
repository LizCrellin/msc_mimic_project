# MSc Data Science final project
## Prediction of prolonged length of stay in intensive care units using routinely collected data: impact of temporal data representation

## Aims and objectives
<p>The overall aim of this project is to develop and evaluate predictive models for prolonged length of stay in ICUs using routinely collected data. This study will approach this with a focus on representations of temporal clinical data and investigate how these influence model performance.</p>

## DATASETS
NB MIMIC IV data are not stored in this repository.<br>
This study uses the MIMIC database, a large publicly available dataset consisting of de-identified data recorded during patient stays in critical care units.  The dataset has been de-identified in accordance with the Health Insurance Portability and Accountability Act (HIPAA) Safe Harbor provision.  The Institutional Review Board of the Beth Israel Deaconess Medical Center approved the sharing of the dataset and granted a waiver of informed consent. Access to the dataset is controlled by PhysioNet, requiring completing of training and signing a data use agreement that prohibits re-identification of individuals and mandates secure data handling practices.<br>
Johnson, A.E.W., Bulgarelli, L., Shen, L., Gayles, A., Shammout, A., Horng, S., Pollard, T.J., Hao, S., Moody, B., Gow, B., Lehman, L.H., Celi, L.A. and Mark, R.G. (2023) “MIMIC-IV, a freely accessible electronic health record dataset,” Scientific Data, 10(1), p. 1. Available at: https://doi.org/10.1038/s41597-022-01899-x.<br>

## Code re-used from other sources
The official MIMIC Code repository was used, with adaptations, to create the PostgreSQL schema, import tables and extract clinical concepts:<br>
MIT-LCP/mimic-code: MIMIC Code v2.2.1<br>
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.6818823.svg)](https://doi.org/10.5281/zenodo.6818823)<br>
https://github.com/MIT-LCP/mimic-code

The MIMIC_Extract pipeline was used, with adaptations, to do parts of the data processing, develop the models, tune hyperparameters and run the logistic regression and random forest models:<br>
Wang, S., McDermott, M.B.A., Chauhan, G., Ghassemi, M., Hughes, M.C. and Naumann, T. (2020) “MIMIC-Extract: A Data Extraction, Preprocessing, and Representation Pipeline for MIMIC-III,” ACM CHIL 2020 - Proceedings of the 2020 ACM Conference on Health, Inference, and Learning. Association for Computing Machinery, Inc, pp. 222–235. Available at: https://doi.org/10.1145/3368555.3384469.<br>
https://github.com/MLforHealth/MIMIC_Extract

Use of code from both repositories is noted in individual scripts where relevant.

## Software
- Windows 11
- postgresql 18.4
- VS Code
- Git 
- Git Bash
- PostgreSQL Management Tool extension for VS Code by Chris Kolkman
- Python (see requirements.txt for a full list of libraries)
- Data Wrangler (Microsoft)

## Setup
The PostgreSQL schemas and tables were created using the create.sql script from the MIMIC Code repository (https://github.com/MIT-LCP/mimic-code/tree/main). This script was run against a PostgreSQL 18.4 database before importing any data.<br>
Data were imported using adapted version of the load_gz.sql script from the MIMIC code repository. Due to limitations to local storage, tables were imported individually in separate SQL scripts.<br>
The project assumes:

- PostgreSQL database: mimiciv
- PostgreSQL user: postgres
- MIMIC-IV version: 3.1

The path to the MIMIC-IV source data is supplied when running the import scripts using the `mimic_data_dir` variable.<br>

The extension PostgreSQL by Chris Kolkman was installed to enable running of SQL queries direct. Need to select connection (Command Palette, PostgreSQL: Select Connection).<br>

I also run full scripts via Git Bash:<br>
psql -U postgres -d mimiciv
- Command to import a file:<br>
psql -U postgres -d mimiciv -v mimic_data_dir="Z:/MSc/mimic-iv-3.1" -f load_gz_stepwise.sql
- Command to run a script:<br>
psql -U postgres -d mimiciv -f load_icustays.sql

Overall using:<br>
- VS Code for editing and Git version control.
- PostgreSQL extension for running ad hoc queries (with Select Connection at the start of a session).
- psql -f in Git Bash for running complete setup/import pipelines and reproducible scripts.
- pgAdmin for browsing data and checking results when it's more convenient.




## Dependencies

## Usage guidelines



## SCRIPTS

| Stage | Script   | Inputs/dependencies | Output | Purpose |
| ----- | ---------| ------ | ------- | ----- |
| Setup | `sql/setup/01_create_mimic_schemas.sql` | NA | NA | Sets up ready to load data |
| Setup | `sql/setup/02_create_project_schemas.sql` | NA | NA | Sets up ready to load data |
| Setup | `sql/setup/03_create_indexes.sql` | NA | NA | Indexing the larger tables for faster processing | 
| Setup | `sql/setup/04_create_sample_ds.sql` | NA | NA | Creates a test version of the database tables based on a random sample of 50 ICU stays | 
| Setup | `python/setup/filter_chartevents.py` | Raw chartevents table | Filtered version of raw chartevents table | Filters the chartevents table to only required codes and columns |
| Setup | `python/setup/filter_labevents.py` | Raw labevents table | Filtered version of raw labevents table | Filters the labevents table to only required codes and columns |
| Setup | `sql/setup/import/load_admissions.sql` | Raw admissions table | Populated table in database | Loads admissions into the database |
| Setup | `sql/setup/import/load_chartevents.sql` | Filtered chartevents table | Populated table in database | Loads chartevents into the database |
| Setup | `sql/setup/import/load_d_items.sql` | Raw d_items table | Populated table in database | Loads d_items into the database |
| Setup | `sql/setup/import/load_d_labitems.sql` | Raw d_labitems table | Populated table in database | Loads d_labitems into the database |
| Setup | `sql/setup/import/load_icustays.sql` | Raw icustays table | Populated table in database | Loads icustays into the database |
| Setup | `sql/setup/import/load_inputevents.sql` | Raw inputevents table | Populated table in database | Loads inputevents into the database |
| Setup | `sql/setup/import/load_labevents.sql` | Filtered labevents table | Populated table in database | Loads labevents into the database |
| Setup | `sql/setup/import/load_patients.sql` | Raw patients table | Populated table in database | Loads patients into the database |
| Cohort | `sql/cohort/patients.sql` | icustays table, patients table, admissions table | derived allpatients view with all ICU stays and details about patient, hospital admission and ICU stay | Extracts relevant details for the eligible ICU stays | 
| Cohort | `sql/cohort/icustay_hourly.sql` | icustays table | derived icustay_hourly view with a row per ICU stay per hour | generates hourly spine |
| Features | `sql/features/project_chemistry.sql` | labevents table | derived chemistry table | extracts relevant concepts for chemistry, setting physiologically implausible values as null |
| Features | `sql/features/project_complete_blood_count.sql` | labevents table | derived complete_blood_count table | extracts relevant concepts for blood counts, setting physiologically implausible values as null | 
| Features | `sql/features/project_gcs.sql` | chartevents table | derived gcs table | calculates Glasgow coma scale from relevant codes in chartevents |
| Features | `sql/features/project_ventdurations.sql` | chartevents table | derived ventdurations table | calculates start and end times for mechanical ventilation |
| Features | `sql/features/project_vitalsign.sql` | chartevents table | derived vitalsign table | extracts relevant concepts for vital signs |
| Features | `sql/features/project_dobutamine.sql` | inputevents table | derived dobutamine table | extracts start and end times for this drug |
| Features | `sql/features/project_dopamine.sql` | inputevents table | derived dopamine table | extracts start and end times for this drug |
| Features | `sql/features/project_epinephrine.sql` | inputevents table | derived epinephrine table | extracts start and end times for this drug |
| Features | `sql/features/project_milrinone.sql` | inputevents table | derived milrinone table | extracts start and end times for this drug |
| Features | `sql/features/project_norepinephrine.sql` | inputevents table | derived norepinephrine table | extracts start and end times for this drug |
| Features | `sql/features/project_phenylephrine.sql` | inputevents table | derived phenylephrine table | extracts start and end times for this drug |
| Features | `sql/features/project_vasopressin.sql` | inputevents table | derived vasopressin table | extracts start and end times for this drug |
| Features | `sql/features/project_vasoactive_agent.sql` | derived tables for vasoactive agents | derived vasoactive_agent view | generates start and end times for any vasoactive agent | 
| Analysis | `sql/analysis/project_hourly_data.sql` | icustay_hourly, allpatients, all derived features tables | derived hourly_aggregated representation | Restricting to the eligible cohort defined in allpatients, joins concepts to the hourly time series spine (icustay_hourly), with values falling in hourly buckets. Where there are more than one value within an hour, these are averaged |
| Analysis | `sql/analysis/project_alternative_data.sql` | allpatients, all derived features tables | derived summary representation | Restricting to the eligible cohort defined in allpatients, a range of summary features are derived from each clinical concept |
| Analysis | `sql/analysis/inclusion_counts.sql` | icustays table | mimiciv_derived.patient_counts table | Generates counts for the inclusion diagram | 
| Analysis | `python/analysis/cohort_descriptive_statistics.sql` | allpatients table | descriptive table output | Generates a table describing study cohort characteristics | 
| Functions | `python/setup/setup_fun.py` | NA | NA | All setup functions in python |


## NOTEBOOKS
| Name | Purpose | 
| ---- | ----- |
| modelling_notebook | Prepare, train and evaluate models for the two derived representations |
| feature_exploration_notebook.ipynb | Explore and describe the features in the two derived representations |
