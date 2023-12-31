#!/bin/bash
# Salesforce DX scratch org alias
# Salesforce DX scratch org alias
ORG_ALIAS=$1
DURATION=$2

echo "ORG_ALIAS : $ORG_ALIAS"
echo "DURATION: : $DURATION"

# Reset current path to be relative to script file
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH

echo ""
echo "Installing org with alias: $ORG_ALIAS"
echo ""

echo "Cleaning previous scratch org..."
sfdx force:org:delete -p -u $ORG_ALIAS
echo ""

echo "Creating scratch org..." && \
cd
cd Desktop
cd 'Work 2'
cd Redtag-Script
sfdx force:org:create  -s -f ./config/project-scratch-def.json -d $DURATION --setdefaultusername -a $ORG_ALIAS &&  \
echo "" && \

echo "Installing NPSP" && \
./install-npsp.sh $ORG_ALIAS && \
echo "" && \

# Get and check last exit code
echo ""
EXIT_CODE="$?"
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "Installation completed."
else
    echo "Installation failed."
fi
exit $EXIT_CODE