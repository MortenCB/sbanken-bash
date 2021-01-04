# This file is to be included and just provides a function to search for a key and return the value
# The actual mapping is in ~/.sbanken.map
# Format of ~/.sbanken.map is abbreviation:accountID.  F.ex:
# s:B6RYyDFJ57828KDUSEE0B3D39C1EDD5364
# visa:1A44F1kd867B2AA1B1kkkd793BC1252E

function aliasToAccountID () {
   local alias
   alias=$1
   l=$(grep "^${alias}:" ~/.sbanken.map 2> /dev/null)
   if [ $? -ne 0 ]; then
      aID="ERROR"
      return 1
   fi
   aID=$(echo "${l}"|cut -d ':' -f 2 2> /dev/null)
   return 0
}
