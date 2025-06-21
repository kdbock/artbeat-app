#!/bin/bash
echo "Deploying updated Firestore security rules..."

# Create a backup of the current rules
cp firestore.rules firestore.rules.backup
echo "Backup created at firestore.rules.backup"

# Deploy the rules
firebase deploy --only firestore:rules

echo "Firestore rules deployed successfully!"
