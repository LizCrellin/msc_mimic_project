############################################################################################
# File: python/setup/filter_chartevents.py
# Created: 18 July 2026
# Modifications:
# 
# TO DO:
# # Adapt this and filter_labevents.py as one function taking input_file, itemid_file, 
# # output_file as arguments.
############################################################################################


import pandas as pd
from pathlib import Path

mimic_data_dir = Path("Z:/MSc/mimic-iv-3.1")
input_file = mimic_data_dir / "icu" / "chartevents.csv.gz"
itemid_file = Path("docs/itemid_list_chartevents.csv")
output_file = mimic_data_dir / "icu" / "chartevents_filtered.csv"

# Store the item id list into a set
itemids = set(pd.read_csv(itemid_file, usecols=[0], header = 0)["itemid"].astype(int))
print("Number of itemids:", len(itemids))
print(itemids)


# for chunk in pd.read_csv(input_file, chunksize=100000):
#     print("Rows in chunk:", len(chunk))
#     filtered_chunk = chunk[chunk["itemid"].isin(itemids)]
#     print("Rows after filtering:", len(filtered_chunk))
#     print(filtered_chunk["itemid"].unique())
#     break

# print(chunk["itemid"].dtype)
# print(type(next(iter(itemids))))

chunk_no = 0
rows_written = 0
for chunk in pd.read_csv(input_file, chunksize = 500000):
    chunk_no += 1
    # keep rows with the relevant itemids
    filtered_chunk = chunk[chunk["itemid"].isin(itemids)][
        ["subject_id", "hadm_id", "stay_id", "charttime", "itemid", "value", "valuenum", "valueuom"]
    ]
    rows_written += len(filtered_chunk)
    # write to output file
    if chunk_no == 1:
        filtered_chunk.to_csv(output_file, index=False, mode='w', header=True)
    else:
        filtered_chunk.to_csv(output_file, index=False, mode='a', header=False)
    print(f"Processed chunk {chunk_no}, filtered rows: {len(filtered_chunk)}")
    print(f"Total rows written: {rows_written}")

print(f"Filtered chartevents saved to {output_file}")

# Check the no of rows for each itemid in the filtered file
filtered = pd.read_csv(
    output_file,
    usecols=["itemid"],
    chunksize=1_000_000
)

counts = {}

for chunk in filtered:
    vc = chunk["itemid"].value_counts()
    for itemid, n in vc.items():
        counts[itemid] = counts.get(itemid, 0) + n

print(counts)
for itemid, count in sorted(counts.items()):
    print(f"| {itemid} | {count:,} |")
