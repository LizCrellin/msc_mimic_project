###############################
# functions for setup
#
# to do:
# type hints, error handling
#############################


import pandas as pd



def filter_itemids(input_file, itemid_file, output_file, column_list):
    '''
    Filter the input file based on selected itemids and save to output file.
    '''
    # Store the item id list into a set
    itemids = set(pd.read_csv(itemid_file, usecols=[0], header = 0)["itemid"].astype(int))
    print("Number of itemids:", len(itemids))
    print(itemids)

    # get list of id columns as these need different treatment when filtering
    idcols = ["subject_id", "hadm_id", "stay_id", "itemid"]

    # read in chunks and output the filtered rows to a new file
    chunk_no = 0
    rows_written = 0
    for chunk in pd.read_csv(input_file, chunksize = 500000):
        chunk_no += 1
        # keep rows with the relevant itemids
        filtered_chunk = chunk[chunk["itemid"].isin(itemids)][column_list]
        rows_written += len(filtered_chunk)
        # ensure id columns are integers
        for col in filtered_chunk.columns: 
            if col in idcols: 
                filtered_chunk[col] = filtered_chunk[col].astype("Int64")
        # write to output file
        if chunk_no == 1:
            filtered_chunk.to_csv(output_file, index=False, mode='w', header=True)
        else:
            filtered_chunk.to_csv(output_file, index=False, mode='a', header=False)
        print(f"Processed chunk {chunk_no}, filtered rows: {len(filtered_chunk)}")
        print(f"Total rows written: {rows_written}")

    print(f"Filtered events saved to {output_file}")
    
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