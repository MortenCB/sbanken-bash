#!/bin/bash
# This script prints out your account list with balance and available funds.
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

# Get accounts:
accounts=$(curl -q -H "customerId: $userId" -H "Authorization: Bearer $token" "https://api.sbanken.no/exec.bank/api/v1/Accounts"  2>/dev/null)
matches=$(echo $accounts|jq -r .availableItems)

# Print out header:
printf "%-20s\t%-11s\t%-10s\n" "Account name" "Account number" "  Balance"
echo "--------------------------------------------------"

# Print out accounts:
for i in $(seq 0 $(($matches - 1)))
do
    accountNumber=$(echo $accounts | jq -r ".items[$i].accountNumber")
    balance=$(echo $accounts | jq -r ".items[$i].balance")
    balance=${balance//./,}
    name=$(echo $accounts | jq -r ".items[$i].name")
    printf "%-20.23s\t%-11s\t%'10.2f\n" "$name" "$accountNumber" $balance
done
