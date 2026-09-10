############################################################################################
# File: python/setup/filter_labevents.py
# Created: 18 July 2026
#
# Purpose: This script filters the labevents table to only the itemids that I need
# for concepts that will be derived, in order to minimise storage needed for the database.
# Additionally limits to relevant columns only.
#
# Modifications:
# Amended to use setup_fun.py to filter labevents based on itemid list
#
# 
############################################################################################

from pathlib import Path
import setup_fun as fun
import os
from dotenv import load_dotenv

load_dotenv()
mimic_data_dir = Path(os.environ["MIMIC_DATA_DIR"])
input_file = mimic_data_dir / "hosp" / "labevents.csv.gz"
itemid_file = Path("docs/itemid_list_labevents.csv")
output_file = mimic_data_dir / "hosp" / "labevents_filtered.csv"
column_list = ["labevent_id", "subject_id", "hadm_id", "specimen_id", "itemid", "order_provider_id", "charttime", "value", "valuenum", "valueuom", "ref_range_lower", "ref_range_upper", "flag", "priority"]


fun.filter_itemids(input_file, itemid_file, output_file, column_list)