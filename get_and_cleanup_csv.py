import pandas as pd
import requests
import time
import pubchempy as pcp

# Import drug-disease csv
print('Importing drug_disease CSV (1/3)...')
drug_disease = pd.read_csv(
    'https://snap.stanford.edu/biodata/datasets/10004/files/DCh-Miner_miner-disease-chemical.tsv.gz',
    delimiter='\t', names=['Disease ID', 'Drug ID'], skiprows=1)

# Initialize the drug name and disease name columns
drug_disease['Disease Name'] = drug_disease['Disease ID']
drug_disease['Drug Name'] = drug_disease['Drug ID']

# Log initial length of DataFrame
print('Beginning drug/disease name retrieval for drug_disease CSV (1/3)...')
initial_length = len(drug_disease)

'''Loop through each row in the DataFrame, querying for the drug id and name,
and disease name at each row. If any error occurs, save time by simply dropping
the row. We should have plenty of data to play with regardless...

Note, for this loop, we are querying both PubChem (via PubChemPy) AND the MeSH
RESTful API Since the given drug IDs are not the standardized compound IDs (cid)
as seen in the next two DataFrames, find the cid of the drug first, replace the
given ID with the found cid (for easy joining when importing into neo4J), then
get that drug's name/synonym.'''
for idx, disease_id, drug_id in zip(drug_disease.index, drug_disease['Disease ID'], drug_disease['Drug ID']):
    # to make sure MeSH querying doesn't time out due to too many requests
    time.sleep(0.1)
    try:
        drug_disease['Disease Name'][idx] = requests.get(
            f"https://id.nlm.nih.gov/mesh/lookup/details?descriptor={disease_id[5:]}&includes=terms").json()['terms'][0]['label']
        drug_data = pcp.get_compounds(drug_id, 'name')[0]
        drug_disease['Drug ID'][idx] = drug_data.cid
        drug_disease['Drug Name'][idx] = drug_data.synonyms[0]
    except:
        drug_disease.drop(labels=idx, axis='index', inplace=True)

# Log the final length of the DataFrame, to see how much data was lost
print('Done with drug/disease name retrieval for drug_disease CSV (1/3)!')
print('Number of lost rows in drug_disease DataFrame:',
      initial_length - len(drug_disease))

# Save the csv
drug_disease.to_csv('drug_disease.csv')
print('drug_disease CSV saved (1/3)!')

# Import drug-drug-side_effect csv
print('Importing drug_interaction_side_effects CSV (2/3)...')
drug_interaction_side_effects = pd.read_csv(
    'https://snap.stanford.edu/biodata/datasets/10017/files/ChChSe-Decagon_polypharmacy.csv.gz',
    names=['Drug 1 ID', 'Drug 2 ID', 'Side Effect ID', 'Side Effect Name'], skiprows=1)

# Log the initial length of the DataFrame
print('Beginning drug name retrieval for drug_interaction_side_effects CSV (2/3)...')
initial_length = len(drug_interaction_side_effects)

# Initialize both of the drug name columns
drug_interaction_side_effects['Drug 1 Name'] = drug_interaction_side_effects['Drug 1 ID']
drug_interaction_side_effects['Drug 2 Name'] = drug_interaction_side_effects['Drug 2 ID']

# Loop through each row in the DataFrame, querying for both drug names at each
# row. If any error occurs, save time by simply dropping the row. We should have
# plenty of data to play with regardless...
for idx, drug1_id, drug2_id in zip(drug_interaction_side_effects.index,
                                   drug_interaction_side_effects['Drug 1 ID'],
                                   drug_interaction_side_effects['Drug 2 ID']):
    try:
        drug_interaction_side_effects['Drug 1 Name'][idx] = pcp.Compound.from_cid(
            int(drug1_id[3:])).synonyms[0]
        drug_interaction_side_effects['Drug 2 Name'][idx] = pcp.Compound.from_cid(
            int(drug2_id[3:])).synonyms[0]
    except:
        drug_interaction_side_effects.drop(
            labels=idx, axis='index', inplace=True)

# Log the final length of the DataFrame, to see how much data was lost
print('Done with drug name retrieval for drug_interaction_side_effects CSV (2/3)!')
print('Number of lost rows in drug_interaction_side_effects DataFrame:',
      initial_length - len(drug_interaction_side_effects))

# Save the csv
drug_interaction_side_effects.to_csv('drug_interaction_side_effects.csv')
print('drug_interaction_side_effects CSV saved (2/3)!')

# Import drug-side_effect csv
print('Importing drug_side_effects CSV (3/3)...')
drug_side_effects = pd.read_csv(
    'https://snap.stanford.edu/biodata/datasets/10018/files/ChSe-Decagon_monopharmacy.csv.gz',
    names=['Drug ID', 'Side Effect ID', 'Side Effect Name'], skiprows=1)

# Initialize the drug name column
drug_side_effects['Drug Name'] = drug_side_effects['Drug ID']

# Log initial length of DataFrame
print('Beginning drug name retrieval for drug_side_effects CSV (3/3)...')
initial_length = len(drug_side_effects)

# Loop through each row in the DataFrame, querying for the drug name at each row
# If any error occurs, save time by simply dropping the row. We should have
# plenty of data to play with regardless...
for idx, drug_id in zip(drug_side_effects.index, drug_side_effects['Drug ID']):
    try:
        drug_side_effects['Drug Name'][idx] = pcp.Compound.from_cid(
            int(drug_id[3:])).synonyms[0]
    except:
        drug_side_effects.drop(labels=idx, axis='index', inplace=True)

# Log the final length of the DataFrame, to see how much data was lost
print('Done with drug/disease name retrieval for drug_side_effects CSV (3/3)!')
print('Number of lost rows in drug_side_effects DataFrame:',
      initial_length - len(drug_side_effects))

# Save the csv
drug_side_effects.to_csv('drug_disease.csv')
print('drug_side_effects CSV saved (3/3)!')
print('All CSV processing done!')
