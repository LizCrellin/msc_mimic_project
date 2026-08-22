###############################################
# Based on the MIMIC-Extract repository:
# hhttps://github.com/MLforHealth/MIMIC_Extract
#
# Original file:
# MIMIC-Extract/notebooks/Summary Stats.ipynb  - UPDATE - ONLY SMALL BITS FROM THIS FILE USED IN THE END.
#
# Accessed: 21 August 2026
#
# Modifications compared to original file:
# 
# TO DO:
# 
#############################


import numpy as np
import pandas as pd
from pathlib import Path
import getpass
from sqlalchemy import create_engine


PROJECT_ROOT = Path.cwd().parents[0]   # adjust after checking Path.cwd()
TABLES_DIR = PROJECT_ROOT / 'msc_project' / 'results' / 'tables'


pg_user = 'postgres'      # same value you use to connect via psql
pg_host = 'localhost'          # or wherever your Postgres server is
pg_port = 5432
pg_dbname = 'mimiciv'

pg_password = getpass.getpass('Postgres password: ')

engine = create_engine(
    f'postgresql+psycopg2://{pg_user}:{pg_password}@{pg_host}:{pg_port}/{pg_dbname}'
)


# read in the icu stays table with only included patients
# method as in notebook

icu_stays = pd.read_sql("SELECT * FROM msc_project.allpatients", engine)

print(icu_stays.head())
print(icu_stays.shape)


# Cohort characteristics for LOS >= 7 days versus shorter length of stay

# PREP LOS_7 VARIABLE
icu_stays['los_7'] = (icu_stays['los_icu'] > 7).astype(int)

# PREP OTHER VARIABLES
# get length of stay in hospital
icu_stays['los_hosp'] = (icu_stays['dischtime'] - icu_stays['admittime']).dt.days
print(icu_stays['los_hosp'])

# Ethnicity - this function adapted from Wang et al.
def categorize_ethnicity(ethnicity):
    if 'ASIAN' in ethnicity:
        ethnicity = 'ASIAN'
    elif 'WHITE' in ethnicity:
        ethnicity = 'WHITE'
    elif 'HISPANIC' in ethnicity:
        ethnicity = 'HISPANIC/LATINO'
    elif 'BLACK' in ethnicity:
        ethnicity = 'BLACK'
    elif 'UNKNOWN' in ethnicity or 'UNABLE TO OBTAIN' in ethnicity or 'DECLINED TO ANSWER' in ethnicity:  # ADDED UNKNOWN CATEGORY
        ethnicity = 'UNKNOWN'
    else: 
        ethnicity = 'OTHER'
    return ethnicity

icu_stays['ethnicity'] = icu_stays['race'].apply(categorize_ethnicity)
# print(sorted(icu_stays['race'].unique(), key=str))
# print(sorted(icu_stays['ethnicity'].unique(), key=str))

# Admission type
def categorize_adm_type(admission_type):
    if 'ELECTIVE' in admission_type or 'SURGICAL SAME DAY' in admission_type:
        admission_type = 'ELECTIVE'
    elif 'URGENT' in admission_type:
        admission_type = 'URGENT'
    elif 'DIRECT EMER' in admission_type or 'EW EMER' in admission_type:
        admission_type = 'EMERGENCY'
    elif 'OBSERVATION' in admission_type:
        admission_type = 'OBSERVATION'
    else: 
        admission_type = 'OTHER'
    return admission_type

icu_stays['admission_type'] = icu_stays['admission_type'].apply(categorize_adm_type)

# Admission location - here I just want to know if admitted from the emergency room or not
def categorize_adm_loc(admission_location):
    if 'EMERGENCY' in admission_location:
        admission_location = 'Emergency room'
    else: 
        admission_location = 'Other/Unknown'
    return admission_location

icu_stays['admission_location'] = icu_stays['admission_location'].apply(categorize_adm_loc)


# Two groups, LOS >= 7 and the rest
group0 = icu_stays[icu_stays['los_7'] == 0]
group1 = icu_stays[icu_stays['los_7'] == 1]

# continuous variables
rows = []
for var in ['admission_age', 'los_icu', 'los_hosp']:
    rows.append({
        'variable': var,
        'los_7 = 0': f'{group0[var].mean():.2f} \u00B1 {group0[var].std():.2f}',
        'los_7 = 1': f'{group1[var].mean():.2f} \u00B1 {group1[var].std():.2f}'
    })

# categorical variables
#print(sorted(icu_stays['gender'].unique(), key=str))

for var in ['gender', 'ethnicity', 'admission_type', 'admission_location', 'hospital_expire_flag']:
    for cat in sorted(icu_stays[var].unique(), key=str):
        rows.append({
            'variable': f'{var}, {cat}',
            'los_7 = 0': f'{(group0[var] == cat).sum()} ({(group0[var] == cat).sum()/len(group0) * 100:.2f}%)',
            'los_7 = 1': f'{(group1[var] == cat).sum()} ({(group1[var] == cat).sum()/len(group1) * 100:.2f}%)'
        })

rows.append({'variable': 'Total',
             'los_7 = 0': f'{group0.sum()},
             'los_7 = 1': f'{group1.sum()}}) 

table1 = pd.DataFrame(rows)
print(table1)

table1.to_csv(TABLES_DIR / 'table1_los7.csv', index=False)