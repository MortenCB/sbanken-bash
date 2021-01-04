#!/bin/bash
# This script prints out any efakturas.
# Morten-Christian Bernson - mc@bernson.net - 4/1 2021

# this script requires `jq` to be installed in order to read json objects.

# Read in passwords from ~/.sbanken_auth
# That file needs to contain three variables:
# 1) clientId which is URL-encoded API-key
# 2) secret which is the password you create in the developer portal
# 3) userId which is your "personnummer"
source ~/.sbanken_auth

# headers
acceptHeader='Accept: application/json'
contentTypeHeader='Content-Type: application/x-www-form-urlencoded; charset=utf-8'

# request body
requestBody='grant_type=client_credentials'

token=$(curl -q -u "$clientId:$secret" -H "$acceptHeader" -H "$contentTypeHeader" -d "$requestBody" 'https://auth.sbanken.no/IdentityServer/connect/token' 2>/dev/null| jq -r .access_token)

# List out efakturas
efakturas=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Efakturas"  2>/dev/null)
matches=$(echo $efakturas | jq -r .availableItems)


# Check if there are any:
if [ $matches -lt 1 ]; then
   echo "No efakturas."
	exit 0
fi

# Print out a header:
printf "%-12s\t%-35s\t%10s\t%-12s\t%-20s\n" "Document type" "From" "Amount" "Due by" "Status"
echo "-------------------------------------------------------------------------------------------------"

# Print out efakturas details:
for i in $(seq 0 $(($matches-1)))
do
   documentType=$(echo $efakturas | jq -r ".items[$i].documentType")
   date=$(echo $efakturas | jq -r ".items[$i].originalDueDate")
   date=$(date -d "$(echo $date | sed 's/T/ /; s/+.*//')" '+%Y-%m-%d')
   amount=$(echo $efakturas | jq -r ".items[$i].originalAmount")
   amount=${amount//./,}
   issuerName=$(echo $efakturas | jq -r ".items[$i].issuerName")
   status=$(echo $efakturas | jq -r ".items[$i].status")
   printf "%-12s\t%-35s\t%'10.2f\t%-12s\t%-20s\n" "$documentType" "$issuerName" $amount "$date" "$status"
done
