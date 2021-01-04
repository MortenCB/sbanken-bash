#!/bin/bash
# This script prints out any scheduled payments for an account.
# Morten-Christian Bernson - mc@bernson.net - 4/1 2021

# this script requires `jq` to be installed in order to read json objects.

# Read in passwords from ~/.sbanken_auth
# That file needs to contain three variables:
# 1) clientId which is URL-encoded API-key
# 2) secret which is the password you create in the developer portal
# 3) userId which is your "personnummer"
source ~/.sbanken_auth

# Get dir of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# This file contains code to convert short abbreviations to the correct account.
# Please edit the "~/.sbanken.map" file to insert your own mapping from short name to accountID.
# See the mapping.inc file for the format.
source "${DIR}/mapping.inc"

# Check for number of arguments, need at least one:
if [ $# -lt 1 ]; then
   echo "This script takes at least one argument. First one is abbreviation for account (according to ~/.sbanken.map), optional second is number of payments to show (default is 100 latest)."
   exit 1
fi

accountIN=$1
if [ $# -gt 1 ]; then
   numTrans=$2
else
   numTrans=100
fi

# Translate account abbreviation to accountID accoring to the mapping.map file:
aliasToAccountID "$accountIN"
if [ "$aID" = "ERROR" ]; then
   echo "Could not convert account abbreviation to accountID.  Please check ~/.sbanken.map."
   exit 1
fi

accountID="$aID"

# headers
acceptHeader='Accept: application/json'
contentTypeHeader='Content-Type: application/x-www-form-urlencoded; charset=utf-8'

# request body
requestBody='grant_type=client_credentials'

token=$(curl -q -u "$clientId:$secret" -H "$acceptHeader" -H "$contentTypeHeader" -d "$requestBody" 'https://auth.sbanken.no/IdentityServer/connect/token' 2>/dev/null| jq -r .access_token)

# List out account information for chose account as a header
account=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Accounts/$accountID"  2>/dev/null)
matches=$(echo "$account" | jq -r .item)

name=$(echo "$matches" | jq -r ".name")
accountNumber=$(echo "$matches" | jq -r ".accountNumber")
available=$(echo "$matches" | jq -r ".available")
available=${available//./,}
balance=$(echo "$matches" | jq -r ".balance")
balance=${balance//./,}

echo -e "$name" '\t' "$accountNumber" '\t' "$available" '\t' "$balance"
echo "------------------------------------------------------------"
echo ""

# List out payments
payments=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Payments/${accountID}?length=$numTrans"  2>/dev/null)
matches=$(echo "$payments" | jq -r .availableItems)

# Check if there are any:
if [ "$matches" -lt 1 ]; then
   echo "No payments."
   exit 0
fi

# Print out a header:
printf "%-35s\t%-13s\t%-12s\t%10s\t%-10s\t%-35s\n" "Recipient" "Rcpt acct#" "Due date" "Amount" "Status" "Text"
echo "-------------------------------------------------------------------------------------------------------------------------------------"

# Print out payments details:
for i in $(seq 0 $(($matches-1)))
do
   recipientAccountNumber=$(echo "$payments" | jq -r ".items[$i].recipientAccountNumber")
   amount=$(echo "$payments" | jq -r ".items[$i].amount")
   amount=${amount//./,}
   date=$(echo "$payments" | jq -r ".items[$i].dueDate")
   date=$(date -d "$(echo "$date" | sed 's/T/ /; s/+.*//')" '+%Y-%m-%d')
   text=$(echo "$payments" | jq -r ".items[$i].text")
   if [ "$text" = "null" ]; then text="";fi;
   status=$(echo "$payments" | jq -r ".items[$i].status")
   beneficiaryName=$(echo "$payments" | jq -r ".items[$i].beneficiaryName")
   if [ "$beneficiaryName" = "null" ]; then beneficiaryName="";fi;
   printf "%-35s\t%-13s\t%-12s\t%'10.2f\t%-10s\t%-35s\n" "$beneficiaryName" "$recipientAccountNumber" "$date" "$amount" "$status" "$text"
done
