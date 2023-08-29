#!/bin/bash
# Unofficial Salesforce DX install script for Salesforce.org NonProfit Success Pack (NPSP)
# https://github.com/pozil/npsp-dx-template

# Salesforce DX scratch org alias
if [ "$#" -eq 1 ]; then
  ORG_ALIAS="$1"
else
  echo "NPSP install failed: missing org alias parameter"
  exit -1
fi

echo ""
echo "Installing NPSP$ on org $ORG_ALIAS"
echo ""

# Gets the latest version of a GitHub repository
# Usage:    getLatestVersion repo
# Example:  getLatestVersion SalesforceFoundation/Cumulus
getLatestVersion() {
  VERSION="$(curl -s "https://api.github.com/repos/$1/releases/latest" | jq -r .name)"
  echo $VERSION
}

# Get the Salesforce package Id (04t....) from the latest version of a GitHub repository
# Usage:    getLatestPackageId repo
# Example:  getLatestPackageId SalesforceFoundation/Cumulus
getLatestPackageId() {
  VERSION="$(curl -s "https://api.github.com/repos/$1/releases/latest" | jq .body)"
  re="installPackage\.apexp\?p0=(04t[a-zA-Z0-9]+)[\\\r\\\n|\"]"
  if [[ $VERSION =~ $re ]]; then
    echo ${BASH_REMATCH[1]};
  else
    echo "Could not extract package Id from repo: $REPO"
    exit -1;
  fi
}

### BEGIN DEPENDENCIES
CONTACTS_AND_ORGANIZATIONS_PACKAGE="$(getLatestPackageId SalesforceFoundation/Contacts_and_Organizations)"
HOUSEHOLDS_PACKAGE="$(getLatestPackageId SalesforceFoundation/Households)"
RECURRING_DONATIONS_PACKAGE="$(getLatestPackageId SalesforceFoundation/Recurring_Donations)"
RELATIONSHIPS_PACKAGE="$(getLatestPackageId SalesforceFoundation/Relationships)"
AFFILIATIONS_PACKAGE="$(getLatestPackageId SalesforceFoundation/Affiliations)"
NPSP_CORE_PACKAGE="$(getLatestPackageId SalesforceFoundation/Cumulus)"
NPSP_CORE_VERSION="$(getLatestVersion SalesforceFoundation/Cumulus)"
### END DEPENDENCIES

echo "Dependencies (automatically fetched from GitHub):"
echo ""
echo "  Contacts and Organizations $CONTACTS_AND_ORGANIZATIONS_PACKAGE"
echo "  Households $HOUSEHOLDS_PACKAGE"
echo "  Recurring Donations $RECURRING_DONATIONS_PACKAGE"
echo "  Relationships $RELATIONSHIPS_PACKAGE"
echo "  Affiliations $AFFILIATIONS_PACKAGE"
echo "  Cumulus $NPSP_CORE_PACKAGE ($NPSP_CORE_VERSION)"
echo ""

# Reset current path to be relative to script file
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH

# Download and extract metadata dependencies to temp folder
echo "Downloading and extracting metadata dependencies..." && \
rm -fr temp && \
mkdir temp && \
cd temp && \
curl "https://github.com/SalesforceFoundation/Cumulus/archive/rel/$NPSP_CORE_VERSION.zip" -L -o npsp.zip && \
unzip npsp.zip "Cumulus-rel-$NPSP_CORE_VERSION/unpackaged/*" && \
mv "Cumulus-rel-$NPSP_CORE_VERSION/unpackaged/" cumulus && \
cd .. && \
echo "" && \

# With Step 8 installing the npsp managed package, this updates the token with the prefix
find temp/cumulus/post/first -type f -exec sed -i '' -e "s/%%%NAMESPACE%%%/npsp__/g" {} \;

# Install dependencies
echo "Installing dependency: Opportunity record types..." && \
sfdx force:mdapi:deploy -d "temp/cumulus/pre/opportunity_record_types" -w 10 -u $ORG_ALIAS && \
echo "" && \

echo "Installing Contacts & Organizations 3.7.05"
sfdx force:package:install -p 04t80000001AWvwAAG -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Household 3.9.0.8"
sfdx force:package:install -p 04t80000000y8tyAAA -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Affiliations 3.6.0.5"
sfdx force:package:install -p 04t80000000lTMlAAM -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing dependency: Account record types..." && \
sfdx force:mdapi:deploy -d "temp/cumulus/pre/account_record_types" -w 10 -u $ORG_ALIAS && \

echo "Installing Relationships 3.6.0.5"
sfdx force:package:install -p 04t80000000y8kRAAQ -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Recurring Donations 3.10.0.4"
sfdx force:package:install -p 04t80000000gZsgAAE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Deploying Metadata"
sfdx force:source:push 

echo "Creating Data in Salesforce"
sfdx force:data:tree:import -p ./data/import-Data-plan.json -u $ORG_ALIAS

echo "Open Org"
sfdx force:org:open -u $ORG_ALIAS

# Remove temp install dir
rm -fr temp && \
echo ""

# Get and check last exit code
EXIT_CODE="$?"
echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "NPSP installation completed."
else
  echo "NPSP installation failed."
fi
exit $EXIT_CODE
