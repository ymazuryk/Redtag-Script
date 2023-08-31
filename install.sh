#!/bin/bash
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
  VERSION="$(curl -s "https://api.github.com/repos/SalesforceFoundation/$1/releases/latest" | jq -r .name)"
  echo $VERSION
}
# Check and Update release version
# Make Sure Package Id is uptodate
getLatestVersionNPSP() {
  VERSION="$(curl -s "https://api.github.com/repos/SalesforceFoundation/$1/releases/115648469" | jq .body)"
  re="installPackage\.apexp\?p0=(04t[a-zA-Z0-9]+)[\\\r\\\n|\"]"
  if [[ $VERSION =~ $re ]]; then
    echo ${BASH_REMATCH[1]};
  else
    echo "Could not extract package Id from repo: $REPO"
    exit -1;
  fi
}

# Get the Salesforce package Id (04t....) from the latest version of a GitHub repository
# Usage:    getLatestPackageId repo
# Example:  getLatestPackageId SalesforceFoundation/Cumulus
getLatestPackageId() {
  VERSION="$(curl -s "https://api.github.com/repos/SalesforceFoundation/$1/releases/latest" | jq .body)"
  re="installPackage\.apexp\?p0=(04t[a-zA-Z0-9]+)[\\\r\\\n|\"]"
  if [[ $VERSION =~ $re ]]; then
    echo ${BASH_REMATCH[1]};
  else
    echo "Could not extract package Id from repo: $REPO"
    exit -1;
  fi
}

### BEGIN DEPENDENCIES
CONTACTS_AND_ORGANIZATIONS_PACKAGE="$(getLatestPackageId Contacts_and_Organizations)"
CONTACTS_AND_ORGANIZATIONS_PACKAGE_VERSION="$(getLatestVersion Contacts_and_Organizations)"

HOUSEHOLDS_PACKAGE="$(getLatestPackageId Households)"
HOUSEHOLDS_PACKAGE_VERSION="$(getLatestVersion Households)"

RECURRING_DONATIONS_PACKAGE="$(getLatestPackageId Recurring_Donations)"
RECURRING_DONATIONS_PACKAGE_VERSION="$(getLatestVersion Recurring_Donations)"

RELATIONSHIPS_PACKAGE="$(getLatestPackageId Relationships)"
RELATIONSHIPS_PACKAGE_VERSION="$(getLatestVersion Relationships)"

AFFILIATIONS_PACKAGE="$(getLatestPackageId Affiliations)"
AFFILIATIONS_PACKAGE_VERSION="$(getLatestVersion Affiliations)"

NPSP_CORE_PACKAGE="$(getLatestVersionNPSP NPSP)"
NPSP_CORE_VERSION="$(getLatestVersion NPSP)"
### END DEPENDENCIES

echo "Dependencies (automatically fetched from GitHub):"
echo ""
echo "  Contacts and Organizations $CONTACTS_AND_ORGANIZATIONS_PACKAGE"
echo "  Households $HOUSEHOLDS_PACKAGE"
echo "  Recurring Donations $RECURRING_DONATIONS_PACKAGE"
echo "  Relationships $RELATIONSHIPS_PACKAGE"
echo "  Affiliations $AFFILIATIONS_PACKAGE"
echo "  NPSP $NPSP_CORE_PACKAGE"
echo ""

echo "Installing Contacts & Organizations Latest Version 1/6 " $CONTACTS_AND_ORGANIZATIONS_PACKAGE_VERSION
sfdx package install -p $CONTACTS_AND_ORGANIZATIONS_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Contacts & Household Latest Version 2/6  " $HOUSEHOLDS_PACKAGE_VERSION
sfdx package install -p $HOUSEHOLDS_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Contacts & RECURRING_DONATIONS_PACKAGE Latest Version 3/6 " $RECURRING_DONATIONS_PACKAGE_VERSION 
sfdx package install -p $RECURRING_DONATIONS_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Contacts & RELATIONSHIPS_PACKAGE Latest Version 4/6 " $RELATIONSHIPS_PACKAGE_VERSION
sfdx package install -p $RELATIONSHIPS_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Contacts & AFFILIATIONS_PACKAGE Latest Version 5/6 " $AFFILIATIONS_PACKAGE_VERSION
sfdx package install -p $AFFILIATIONS_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

echo "Installing Contacts & NPSP_CORE_PACKAGE Latest Version 5/6 " $NPSP_CORE_VERSION
sfdx package install -p $NPSP_CORE_PACKAGE -w 5 -u $ORG_ALIAS --noprompt && \

# Reset current path to be relative to script file
SCRIPT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd $SCRIPT_PATH


# With Step 8 installing the npsp managed package, this updates the token with the prefix
find temp/cumulus/post/first -type f -exec sed -i '' -e "s/%%%NAMESPACE%%%/npsp__/g" {} \;

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
