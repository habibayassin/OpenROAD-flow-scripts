import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
import json
import argparse
import re
import os

# Create the argument parser
parser = argparse.ArgumentParser(description='Process some integers.')

# Add the named arguments
parser.add_argument('--buildID', type=str, help='Build ID from jenkins')
parser.add_argument('--branchName', type=str, help='Current Branch Name')
parser.add_argument('--pipelineID', type=str, help='Jenkins pipeline ID')
parser.add_argument('--commitSHA', type=str, help='Current commit sha')
parser.add_argument('--keyFile', type=str, help='Service account credentials key file')
parser.add_argument("--variant", type=str, default="base")

# Parse the arguments
args = parser.parse_args()

def upload_data(datafile, platform, design, variant, args):
    # Initialize Firebase Admin SDK with service account credentials
    cred = credentials.Certificate(args.keyFile)
    firebase_admin.initialize_app(cred)

    # Initialize Firestore client
    db = firestore.client()

    # Set the document data
    key = args.commitSHA + '-' + platform + '-' + design + '-' + variant
    doc_ref = db.collection('collection_name').document(key)
    doc_ref.set({
        'build_id': args.buildID,
        'branch_name': args.branchName,
        'pipeline_id': args.pipelineID,
        'commit_sha': args.commitSHA,
    })

    # Load JSON data from file
    with open(dataFile) as f:
        data = json.load(f)    

    # Replace the character ':' in the keys
    new_data = {}
    for k, v in data.items():
        new_key = re.sub(':', '__', k)  # replace ':' with '__'
        new_data[new_key] = v

    # Set the data to the document in Firestore
    doc_ref.update(new_data)

runFilename = f'metadata-{args.variant}.json'

for reportDir, dirs, files in sorted(os.walk('reports', topdown=False)):
    dirList = reportDir.split(os.sep)
    if len(dirList) != 4:
        continue

    # basic info about test design
    platform = dirList[1]
    design = dirList[2]
    variant = dirList[3]
    test = '{} {} {}'.format(platform, design, variant)
    print(test)
    dataFile = os.path.join(reportDir, runFilename)
    upload_data(dataFile, platform, design, variant, args)
