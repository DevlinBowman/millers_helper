# ledger

The ledger itself is a system for maintaining a transaction history. It uses the systems ledger store to write files which are associated with a primary index. 

The ledger operates in individual job batches. each batch is treated as a singular transaction which requires a minimum context to be committed. when commiting a batch the index is populated with some reference data defined in the ledgers' schema, ans associated files are linked via a transaction id.

## shape
index:
    the index is the primary surface for the ledger data. on read or write everything talks to it. 
bundles:
    bundles is a storage location that contain txn dirs
txn dirs:
    each txn dir contain 2 sub dirs; 1 for the primary data (board|order|entry|...) and 1 for attachments (invoice|quote|notes|other|...)

# primary capabilities

## load
load():
    load can take in a batch or batches and simply runs validation to see which are legal to commit. it returns the indexes for each submitted batch with a message containing 'ready', or 'incomplete' and what is missing from the requirements

validate:
    the validation phase checks that batches ingested into the ledger contain the minimum data requires for a legal entry.

## write

commit:
    commiting to the ledger can happen on the scope of an individual batch or an entire job as individual batches. to commit to the ledger each batch must pass the validation phase. it uses only 'ready' indexes from the load, and complains about any others. on commit, the index is update per transaction, and the associated files are written to the store.

## read

read(index_file):
    reads the ledger index and builds an envelope of canonical data per item within it sourcing the associated files in the store per entry. it will also additionally contain filed for attachments as a list of links to any attachment files for item.

## get

get()
    allows selection and targeting of any 1, range, or all of the transaction from the index. this us used with read for post ingestion data access by any arbitrary scope.







