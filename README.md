# sbanken-bash
Bash scripts to do your banking with Sbanken (norwegian bank) through their official APIs.

1) Go to sbanken and opt in for their beta bank
2) Login to the api at https://secure.sbanken.no/Personal/ApiBeta/Info
3) Get your API key and app password
4) Make ~/sbanken_auth with the following variables:
  1) clientId which is URL-encoded API-key
  2) secret which is the password you create in the developer portal
  3) userId which is your "personnummer"
5) Make ~/sbanken.map with the list of your abbreviations translated to accountID (can be listed with accountlist.sh). Example of a line in the mapping-file: s:B6RYyDFJ57828KDUSEE0B3D39C1EDD5364

