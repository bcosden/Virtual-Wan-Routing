#!/bin/bash

# Set up a JIT access policy to enable SSH.
# This script only needs to be run once post deployment to create the policy
#
# NOTE: IF JIT is NOT enabled for your subscription turn on enablejit flag below
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

enablejit=false

subid=$(az account show --query 'id' -o tsv)

if [ $enablejit = 'true' ]; then

    uri='https://management.azure.com/subscriptions/'$subid'/providers/Microsoft.Security/pricings/VirtualMachines?api-version=2022-03-01'
    json='{
    "properties": {
        "pricingTier": "Standard",
        "subPlan": "P2"
    }
    }'

    az rest --method PUT \
    --url $uri  \
    --body "$json" \
    --output none
fi

# Get array of VM's and locations in resource group
arr=($(az vm list -g $rg --query '[].{Name:name, Loc:location}' -o tsv))
arrlen=${#arr[@]}

# Create JIT policy
for (( x=1; x<=$arrlen; x=x+2 ))
do
    name=${arr[x]}
    loc=${arr[x+1]}
    echo -e "$WHITE$(date +"%T")$GREEN Creating JIT policy for $CYAN" $name "$GREEN in $CYAN" $loc

    # create JIT policy for each VM
    uri='https://management.azure.com/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Security/locations/'$loc'/jitNetworkAccessPolicies/'$name'?api-version=2020-01-01'
    json='{
    "kind": "Basic",
    "properties": {
        "virtualMachines": [
        {
            "id": "/subscriptions/'$subid'/resourceGroups/'$rg'/providers/Microsoft.Compute/virtualMachines/'$name'",
            "ports": ['
                len=${#ports[@]}
                for (( i=1; i<=$len; i++ ))
                do
                    json+='{
                    "number": "'${ports[$i]}'",
                    "maxRequestAccessDuration": "PT24H",
                    "protocol": "*",
                    "allowedSourceAddressPrefix": "*"
                    }'
                        if [ $i -lt $((len-1)) ]; then
                            json+=','
                        fi
                done
            json+=']
            }
        ]
        }
    }'

    az rest --method PUT \
        --url $uri  \
        --body "$json" \
        --output none
done
