#!/bin/bash

# Turn on JIT access to enable SSH.
# This script needs to be run each time you want to access a VM if the previous policy access has expired
#
# NOTE: The duration of access is set to 12 hours below.
#

rg="vwan-bgp"

# format as an array. In this case open SSH only
ports=(22)

# default duration of 12 hours of access
dur=12

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

subid=$(az account show --query 'id' -o tsv)

# Get array of VM's and locations in resource group
arr=($(az vm list -g $rg --query '[].{Name:name, Loc:location}' -o tsv))
arrlen=${#arr[@]}

# Enable JIT policy
for (( x=1; x<=$arrlen; x=x+2 ))
do
    name=${arr[x]}
    loc=${arr[x+1]}
    echo -e "$WHITE$(date +"%T")$GREEN Enabling JIT policy for $CYAN" $name "$GREEN in $CYAN" $loc

    ip=$(curl -s -4 ifconfig.io)
    uri='https://management.azure.com/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Security/locations/'$loc'/jitNetworkAccessPolicies/'$name'/initiate?api-version=2020-01-01'
    json='{
    "virtualMachines": [
        {
        "id": "/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Compute/virtualMachines/'$name'",
        "ports": ['
            len=${#ports[@]}
            for (( i=1; i<=$len; i++ ))
            do
                json+='{
                "number": "'${ports[$i]}'",
                "duration": "PT'$dur'H",
                "allowedSourceAddressPrefix": "'$ip'"
                }'
                    if [ $i -lt $((len-1)) ]; then
                        json+=','
                    fi
            done
        json+=']
        }
    ],
    "justification": "Doing some testing ....."
    }'

    az rest --method POST \
        --url $uri  \
        --body "$json" \
        --output none
done
