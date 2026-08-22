###############################################
# Based on the MIMIC-Extract repository:
# hhttps://github.com/MLforHealth/MIMIC_Extract
#
# Original file:
# MIMIC-Extract/notebooks/Summary Stats.ipynb
#
# Accessed: 21 August 2026
#
# Modifications compared to original file:
# 
# 
#
# TO DO:
# 
#############################


import numpy as np
import pandas as pd
from scipy.stats import ttest_ind_from_stats, spearmanr
from sklearn.preprocessing import StandardScaler
import matplotlib.pyplot as plt
import getpass
from sqlalchemy import create_engine

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

icu_stays['los_7'] = (icu_stays['los_icu'] > 7).astype(int)

# get length of stay in hospital
icu_stays['los_hosp'] = (icu_stays['dischtime'] - icu_stays['admittime']).dt.days
print(icu_stays['los_hosp'])

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

print(sorted(icu_stays['gender'].unique(), key=str))

#for var in ['gender', 'race', 'admission_type', 'admission_location', 'hospital_expire_flag'],
    

table1 = pd.DataFrame(rows)
print(table1)