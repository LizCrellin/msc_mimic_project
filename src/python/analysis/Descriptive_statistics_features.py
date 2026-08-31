###############################################
# Exploration of feature distributions and correlations
#
#
# Drafted: 31 August 2026
#
# TO DO:
# 
#############################


import numpy as np
import pandas as pd
from pathlib import Path
import getpass
from sqlalchemy import create_engine, text
import os
from dotenv import load_dotenv


PROJECT_ROOT = Path.cwd().parents[0]   # adjust after checking Path.cwd()
TABLES_DIR = PROJECT_ROOT / 'msc_project' / 'results' / 'tables'
load_dotenv()
BACKUP_ROOT = Path(os.environ["BACKUP_ROOT"])
DATA_DIR = BACKUP_ROOT / 'results' / 'data'
REPRESENTATIVE_VARS = ['heart_rate', 'sbp', 'dbp', 'resp_rate', 'spo2', 'gcs', 'creatinine', 'potassium', 'wbc']


pg_user = 'postgres'      # same value you use to connect via psql
pg_host = 'localhost'          # or wherever your Postgres server is
pg_port = 5432
pg_dbname = 'mimiciv'

pg_password = getpass.getpass('Postgres password: ')

engine = create_engine(
    f'postgresql+psycopg2://{pg_user}:{pg_password}@{pg_host}:{pg_port}/{pg_dbname}'
)

# Restrict to Train dataset
Ys_train = pd.read_parquet(DATA_DIR / 'Ys_train.parquet', engine='pyarrow')
train_ids = sorted(set(Ys_train.index.get_level_values('icustay_id')))
n_train = len(train_ids)
print(n_train)

# read in the hourly aggregated dataset

hourly_ds = pd.read_sql(text("SELECT * FROM msc_project.hourly_data WHERE icustay_id = ANY(:ids)"), engine, params = {'ids': train_ids})

hourly_id_cols = ['subject_id', 'hadm_id', 'icustay_id', 'hours_in', 'hour_end']
hourly_vars = [c for c in hourly_ds.columns if c not in hourly_id_cols]



# # read in the summary representation dataset

# summary_ds = pd.read_sql("SELECT * FROM msc_project.alternative_data", engine)

