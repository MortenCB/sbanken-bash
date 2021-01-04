#!/bin/bash
# This script prints out the last x transactions for an account. Default is 10 latest.
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
source ${DIR}/mapping.inc

# Check for number of arguments, need at least one:
if [ $# -lt 1 ]; then
   echo "This script takes at least one agrument. First one is abbreviation for account (according to ~/.sbanken.map), optional second is number of transactions to show (default is 10 latest)."
        exit 1
fi

accountIN=$1
if [ $# -gt 1 ]; then
   numTrans=$2
else
   numTrans=10
fi

# Translate account abbreviation to accountID accoring to the mapping.map file:
aliasToAccountID $accountIN
if [ "$aID" = "ERROR" ]; then
   echo "Could not convert account abbreviation to accountID.  Please check ~/.sbanken.map."
        exit 1
fi

accountID=$aID

# headers
acceptHeader='Accept: application/json'
contentTypeHeader='Content-Type: application/x-www-form-urlencoded; charset=utf-8'

# request body
requestBody='grant_type=client_credentials'

token=$(curl -q -u "$clientId:$secret" -H "$acceptHeader" -H "$contentTypeHeader" -d "$requestBody" 'https://auth.sbanken.no/IdentityServer/connect/token' 2>/dev/null| jq -r .access_token)

# List out account information for chose account as a header
account=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Accounts/$accountID"  2>/dev/null)
matches=$(echo $account|jq -r .item)

name=$(echo $matches | jq -r ".name")
accountNumber=$(echo $matches | jq -r ".accountNumber")
available=$(echo $matches | jq -r ".available")
available=${available//./,}
balance=$(echo $matches | jq -r ".balance")
balance=${balance//./,}

echo -e $name '\t' $accountNumber '\t' $available '\t' $balance
echo "------------------------------------------------------------"
echo ""

# Get transactions for this account:
transactions=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Transactions/${accountID}?length=${numTrans}" 2>/dev/null)

printf "%-12s\t%-18s\t%-50s\t%12s\n" "Date" "Transaction type" "Text for transaction" "Amount  "
echo "----------------------------------------------------------------------------------------------------------"

# Print out last x number of transations:
for i in $(seq 0 $(($numTrans-1)))
do
   text=$(echo $transactions | jq -r ".items[$i].text")
        amount=$(echo $transactions | jq -r ".items[$i].amount")
        amount=${amount//./,}
        trType=$(echo $transactions | jq -r ".items[$i].transactionType")
        accDate=$(echo $transactions | jq -r ".items[$i].accountingDate")
        accDate=$(date -d "$(echo $accDate | sed 's/T/ /; s/+.*//')" '+%Y-%m-%d')
        intDate=$(echo $transactions | jq -r ".items[$i].interestDate")
        intDate=$(date -d "$(echo $intDate | sed 's/T/ /; s/+.*//')" '+%Y-%m-%d')
        printf "%-12s\t%-18s\t%-50s\t%'10.2f\n" "$accDate" "$trType" "$text" $amount
done
