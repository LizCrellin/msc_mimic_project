# MSc Data Science project
## Prediction of prolonged length of stay in intensive care units using routinely collected data: impact of temporal data representation

## Aims
<p>The aim of this project is to develop and evaluate predictive models for prolonged length of stay in ICUs using routinely collected data, with a focus on representations of temporal clinical data.</p>

## Datasets
The MIMIC IV v.3.1 data are not stored in this repository.<br>
This study uses the MIMIC IV v.3.1  database, a large publicly available dataset consisting of de-identified data recorded during patient stays in critical care units.  The dataset has been de-identified in accordance with the Health Insurance Portability and Accountability Act (HIPAA) Safe Harbor provision.  The Institutional Review Board of the Beth Israel Deaconess Medical Center approved the sharing of the dataset and granted a waiver of informed consent. Access to the dataset is controlled by PhysioNet, requiring completing of training and signing a data use agreement that prohibits re-identification of individuals and mandates secure data handling practices.<br>
Johnson, A., Bulgarelli, L., Pollard, T., Gow, B., Moody, B., Horng, S., Celi, L. A., & Mark, R. (2024). MIMIC-IV (version 3.1). PhysioNet. RRID:SCR_007345. https://doi.org/10.13026/kpb9-mt58<br>
Johnson, A.E.W., Bulgarelli, L., Shen, L., Gayles, A., Shammout, A., Horng, S., Pollard, T.J., Hao, S., Moody, B., Gow, B., Lehman, L.H., Celi, L.A. and Mark, R.G. (2023) “MIMIC-IV, a freely accessible electronic health record dataset,” Scientific Data, 10(1), p. 1. Available at: https://doi.org/10.1038/s41597-022-01899-x.<br>

## Code re-used from other sources
The official MIMIC Code repository was used, with adaptations, to create the PostgreSQL schema, import tables and extract clinical concepts:<br>
MIT-LCP/mimic-code: MIMIC Code v2.2.1<br>
https://doi.org/10.5281/zenodo.6818823<br>
https://github.com/MIT-LCP/mimic-code

The MIMIC_Extract pipeline was used, with adaptations, to do parts of the data processing, develop the models, tune hyperparameters and run the logistic regression and random forest models:<br>
Wang, S., McDermott, M.B.A., Chauhan, G., Ghassemi, M., Hughes, M.C. and Naumann, T. (2020) “MIMIC-Extract: A Data Extraction, Preprocessing, and Representation Pipeline for MIMIC-III,” ACM CHIL 2020 - Proceedings of the 2020 ACM Conference on Health, Inference, and Learning. Association for Computing Machinery, Inc, pp. 222–235. Available at: https://doi.org/10.1145/3368555.3384469.<br>
https://github.com/MLforHealth/MIMIC_Extract

Use of code from both repositories is noted in individual scripts where relevant.

## Setup

### Prerequisites
- Windows 11
- Postgresql 18.4
- Python 3.12.5
- VS Code
- PostgreSQL Management Tool extension for VS Code by Chris Kolkman
- Git 
- Git Bash
- Access to the MIMIC IV v3.1 data via PhysioNet (see Datasets section above for access requirements)
- Enough disk space for the raw source MIMIC IV v3.1 to be downloaded and stored (approximately 22 GB unzipped) and the PostgreSQL database once set up (approximately 24 GB. NB this is smaller than the full MIMIC IV v3.1 database as only the tables required for the proejct are imported and the largest tables are filtered.)

### Steps to set up and run the project

1. Clone the repository

``` 
git clone https://github.com/LizCrellin/msc_mimic_project
```
2. Set up Python environment
``` 
cd msc_project
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
``` 
3. Create '.env' file<br>
Set up file paths for the location where the MIMIC IV data has been downloaded and stored, and a separate backup location for saving processed data, trained models and results.
``` 
MIMIC_DATA_DIR={path to source MIMIC data location}
BACKUP_ROOT={path to backup location}
``` 
4. Set up PostgreSQL database<br>
The project assumes:<br>

- PostgreSQL database: mimiciv
- PostgreSQL user: postgres
- MIMIC-IV version: 3.1

Run the script `src/sql/setup/01_create_mimic_schemas.sql`, adapted from the create.sql script in the MIT-LCP/mimic-code repository. This script was run against a PostgreSQL 18.4 database before importing any data.<br>
Run `src/sql/setup/02_create_project_schemas.sql` to generate an additional schema for the project.<br>

5. Import the raw MIMIC IV data<br>
Filter the two largest tables prior to import:<br>
`src/python/setup/filter_chartevents.py`<br>
`src/python/setup/filter_labevents.py`<br>
Import the raw tables using the scripts under `src/sql/setup/import/`.
Tables are imported individually due to local storage limits.

Example:
```bash
psql -U postgres -d mimiciv -v mimic_data_dir="{file_path}" -f load_admissions.sql
```

6. Run SQL pipeline<br>
Example:
```bash
psql -U postgres -d mimiciv -f icustay_hourly.sql
```

i) Setup - run remaining set up scripts:<br>
`03_create_indexes.sql`<br>
`04_create_sample_ds.sql`- optional creation of sample dataset for testing and iteration<br>

ii) Cohort<br>
`src/sql/cohort/patients.sql`<br>
`src/sql/cohort/icustay_hourly.sql`<br>

iii) Features<br>
Run scripts under `src/sql/features`.  <br>
See the full list of scripts for information on which are essential to the final outputs.<br>

iv) Analysis prep<br>
Build the two representations:<br>
`src/sql/analysis/project_hourly_data.sql` <br>
`src/sql/analysis/project_alternative_data.sql`<br>

v) Analysis outputs<br>
Generate inclusion counts:<br>
`src/sql/analysis/inclusion_counts.sql`<br>
Generate descriptive statistics about the cohort:<br>
`src/python/analysis/cohort_descriptive_statistics.py`<br>
Feature exploration and descriptive outputs:<br>
`notebooks/feature_exploration_notebook.ipynb`<br>
Prepare, train and evaluate models for the two derived representations:<br>
`notebooks/modelling_notebook.ipynb`<br>
The notebooks connect to PostgreSQL, and will prompt for the Postgres password interactively when run.<br>
`notebooks/modelling_notebook.ipynb` has a 'testing' flag which can be set to run the notebook on the test/sample datasets, if created (`04_create_sample_ds.sql`).

## Scripts

### Repository structure
| Folder | Purpose | 
| ---- | ----- |
| `src/sql/setup` | Creation of schemas, indexing, setting up sample tables |
| `src/sql/setup/import` | Importing data into the database |
| `src/python/setup` | Filtering raw tables prior to import into the database |
| `src/sql/cohort` | Create the analysis cohort and hourly spine |
| `src/sql/features` | Extracts relevant concepts for inclusion in the models | 
| `src/sql/analysis` | Creation of the combined datasets for analysis, deriving counts for inclusion diagram |
| `src/python/analysis` | Cohort descriptive statistics | 
| `notebooks` | Notebooks for feature exploration and modelling | 


### Individual scripts
| Stage | Script   | Inputs/dependencies | Output | Purpose | Required to generate outputs |
| ----- | ---------| ------ | ------- | ----- |-------|
| Setup | `src/sql/setup/01_create_mimic_schemas.sql` | NA | NA | Sets up ready to load data | Yes | 
| Setup | `src/sql/setup/02_create_project_schemas.sql` | NA | NA | Sets up ready to load data | Yes |
| Setup | `src/sql/setup/03_create_indexes.sql` | NA | NA | Indexing the larger tables for faster processing | No | 
| Setup | `src/sql/setup/04_create_sample_ds.sql` | NA | NA | Creates a test version of the database tables based on a random sample of 50 ICU stays | No |
| Setup | `src/python/setup/filter_chartevents.py` | Raw chartevents table | Filtered version of raw chartevents table | Filters the chartevents table to only required codes and columns | N | 
| Setup | `src/python/setup/filter_labevents.py` | Raw labevents table | Filtered version of raw labevents table | Filters the labevents table to only required codes and columns | N |
| Setup | `src/sql/setup/import/load_admissions.sql` | Raw admissions table | Populated table in database | Loads admissions into the database | Y |
| Setup | `src/sql/setup/import/load_chartevents.sql` | Filtered chartevents table | Populated table in database | Loads chartevents into the database | Y |
| Setup | `src/sql/setup/import/load_d_items.sql` | Raw d_items table | Populated table in database | Loads d_items into the database | Y |
| Setup | `src/sql/setup/import/load_d_labitems.sql` | Raw d_labitems table | Populated table in database | Loads d_labitems into the database | Y |
| Setup | `src/sql/setup/import/load_icustays.sql` | Raw icustays table | Populated table in database | Loads icustays into the database | Y |
| Setup | `src/sql/setup/import/load_inputevents.sql` | Raw inputevents table | Populated table in database | Loads inputevents into the database | Y |
| Setup | `src/sql/setup/import/load_labevents.sql` | Filtered labevents table | Populated table in database | Loads labevents into the database | Y |
| Setup | `src/sql/setup/import/load_patients.sql` | Raw patients table | Populated table in database | Loads patients into the database | Y |
| Cohort | `src/sql/cohort/patients.sql` | icustays table, patients table, admissions table | derived allpatients view with all ICU stays and details about patient, hospital admission and ICU stay | Extracts relevant details for the eligible ICU stays | Y |
| Cohort | `src/sql/cohort/icustay_hourly.sql` | icustays table | derived icustay_hourly view with a row per ICU stay per hour | generates hourly spine | Y |
| Features | `src/sql/features/project_chemistry.sql` | labevents table | derived chemistry table | extracts relevant concepts for chemistry, setting physiologically implausible values as null | Y |
| Features | `src/sql/features/project_complete_blood_count.sql` | labevents table | derived complete_blood_count table | extracts relevant concepts for blood counts, setting physiologically implausible values as null | Y |
| Features | `src/sql/features/project_gcs.sql` | chartevents table | derived gcs table | calculates Glasgow coma scale from relevant codes in chartevents | Y |
| Features | `src/sql/features/project_ventdurations.sql` | chartevents table | derived ventdurations table | calculates start and end times for mechanical ventilation | N |
| Features | `src/sql/features/project_vitalsign.sql` | chartevents table | derived vitalsign table | extracts relevant concepts for vital signs | Y |
| Features | `src/sql/features/project_dobutamine.sql` | inputevents table | derived dobutamine table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_dopamine.sql` | inputevents table | derived dopamine table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_epinephrine.sql` | inputevents table | derived epinephrine table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_milrinone.sql` | inputevents table | derived milrinone table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_norepinephrine.sql` | inputevents table | derived norepinephrine table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_phenylephrine.sql` | inputevents table | derived phenylephrine table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_vasopressin.sql` | inputevents table | derived vasopressin table | extracts start and end times for this drug | N |
| Features | `src/sql/features/project_vasoactive_agent.sql` | derived tables for vasoactive agents | derived vasoactive_agent view | generates start and end times for any vasoactive agent | N |
| Features | `src/sql/features/project_RRT.sql` | chartevents, inputevents and procedureevents tables | extracts times of RRT (present or active) | N |
| Analysis | `src/sql/analysis/project_hourly_data.sql` | icustay_hourly, allpatients, all derived features tables | derived hourly_aggregated representation | Restricting to the eligible cohort defined in allpatients, joins concepts to the hourly time series spine (icustay_hourly), with values falling in hourly buckets. Where there are more than one value within an hour, these are averaged | Y |
| Analysis | `src/sql/analysis/project_alternative_data.sql` | allpatients, all derived features tables | derived summary representation | Restricting to the eligible cohort defined in allpatients, a range of summary features are derived from each clinical concept | Y |
| Analysis | `src/sql/analysis/inclusion_counts.sql` | icustays table | mimiciv_derived.patient_counts table | Generates counts for the inclusion diagram | Y |
| Analysis | `src/python/analysis/cohort_descriptive_statistics.py` | allpatients table | descriptive table output | Generates a table describing study cohort characteristics | Y |
| Functions | `src/python/setup/setup_fun.py` | NA | NA | All setup functions in python | Y | 
| Explore | `src/sql/explore/explore_data.sql` | NA | NA | General purpose script for exploring the database tables | N | 

## NOTEBOOKS
| Name | Purpose | Required to generate outputs |
| ---- | ----- | --- |
| `notebooks/feature_exploration_notebook.ipynb` | Explore and describe the features in the two derived representations | Y |
| `notebooks/modelling_notebook.ipynb` | Prepare, train and evaluate models for the two derived representations | Y |

