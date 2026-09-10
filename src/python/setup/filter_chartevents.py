############################################################################################
# File: python/setup/filter_chartevents.py
# Created: 18 July 2026
#
# Purpose: This script filters the chartevents table to only the itemids that I need
# for concepts that will be derived, in order to minimise storage needed for the database.
# Additionally limits to relevant columns only.
#
# Modifications:
# Amended to use setup_fun.py to filter chartevents based on itemid list
############################################################################################


from pathlib import Path
import setup_fun as fun
import os
from dotenv import load_dotenv

load_dotenv()
mimic_data_dir = Path(os.environ["MIMIC_DATA_DIR"])
input_file = mimic_data_dir / "icu" / "chartevents.csv.gz"
itemid_file = Path("docs/itemid_list_chartevents.csv")
output_file = mimic_data_dir / "icu" / "chartevents_filtered.csv"
column_list = ["subject_id", "hadm_id", "stay_id", "charttime", "itemid", "value", "valuenum", "valueuom"]


fun.filter_itemids(input_file, itemid_file, output_file, column_list)