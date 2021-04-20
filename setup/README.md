# Setup instructions

1. In the folder where you've cloned this repo, activate your preferred conda environment (`conda activate <env>`)
2. Install the required packages: `conda install pandas requests time`, `conda install -c bioconda pubchempy`
3. In the folder where you've cloned this repo, first run the `get_and_cleanup_csv.py` script: `python setup/get_and_cleanup_csv.py` (This script will take approximately 10-15 minutes to run)
4. Once you've produced the 3 CSV results: `drug_disease.csv`, `drug_interaction_side_effects.csv`, and `drug_side_effects.csv` (all 3 should be in the `data/` folder), run the `neo4j_admin_import_prep.py` script: `python setup/neo4j_admin_import_prep.py`
5. Once you've produced the resulting CSVs (all end in`nodes.csv` or `edges.csv`, and all should be in the `data/` folder), copy (or move) all of them into your `$NEO4J_HOME/import` folder: `cp data/*nodes.csv data/*edges.csv $NEO4J_HOME/import`
6. Change directories to your `$NEO4J_HOME`
7. If Neo4J is running, stop it first: `neo4j stop`
8. Ensure that your Neo4J database is empty (feel free to back up the following directories before you do so if you need to restore your neo4j database later): `rm -rf $NEO4J_HOME/data/databases/neo4j/*` and `rm -rf $NEO4J_HOME/data/transactions/neo4j/*`
9. Ensure that you're using Java11
10. Run the `neo4j-import.sh` script from your `$NEO4J_HOME` directory (you may need to give it permissions first using chmod, depending on how you run it): `./path/to/this/repo/setup/neo4j-import.sh` or `bash /path/to/this/repo/setup/neo4j-import.sh`
11. Now you're ready to explore the database! Run `neo4j start` to start Neo4J and log into the `neo4j` database to start looking at this data!
