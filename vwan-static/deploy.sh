#!/bin/bash

# VARIABLES
loc1="eastus"
loc2="westus"
rg="vwan-nva"

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
PINK="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
NORMAL="\033[0;39m"

usessh=true
useexr=false

nva1="frreastVM"
nva2="frrwestVM"
username="azureuser"
password="MyP@ssword123"
vmsize="Standard_D2S_v3"

hubeastvpn="hubeastvpn"$RANDOM
hubwestvpn="hubwestvpn"$RANDOM

nvaipeast=10.1.0.10
nvaipeastext=10.1.1.10
nvaipwest=10.2.0.10
nvaipwestext=10.2.1.10

# Allow RG to be set via shell var
if [[ $1 ]]; then
    rg=$1
fi

# create resource group
echo -e "$WHITE$(date +"%T")$GREEN Creating Resource Group$CYAN" $rg "$GREEN in $CYAN" $loc1
az group create -n $rg -l $loc1 -o none

# create virtual wan
echo -e "$WHITE$(date +"%T")$GREEN Creating Virtual WAN $WHITE"
az network vwan create -g $rg -n vwannva --branch-to-branch-traffic true --location $loc1 --type Standard -o none

# create vhubs
echo -e "$WHITE$(date +"%T")$GREEN Creating East Hub $WHITE"
az network vhub create -g $rg --name hubeast --address-prefix 10.0.0.0/24 --vwan vwannva --location $loc1 --sku Standard -o none
echo -e "$WHITE$(date +"%T")$GREEN Creating West Hub $WHITE"
az network vhub create -g $rg --name hubwest --address-prefix 10.0.1.0/24 --vwan vwannva --location $loc2 --sku Standard -o none

# create VPN gateways in each vhub
echo -e "$WHITE$(date +"%T")$GREEN Creating Hub VPN GW (no-wait) $WHITE"
az network vpn-gateway create -n hubeastvpn -g $rg --location $loc1 --vhub hubeast  --no-wait
az network vpn-gateway create -n hubwestvpn -g $rg --location $loc2 --vhub hubwest --no-wait

# EAST SPOKES
# create nva virtual network
echo -e "$WHITE$(date +"%T")$GREEN Creating Virtual Network nvaEastVnet $WHITE"
az network vnet create --address-prefixes 10.1.0.0/16 -n nvaEastVnet -g $rg -l $loc1 --subnet-name internal --subnet-prefixes 10.1.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating subnets $WHITE"
echo ".... creating external"
az network vnet subnet create -g $rg --vnet-name nvaEastVnet -n external --address-prefixes 10.1.1.0/24 -o none

# create spoke virtual network
echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke1east $WHITE"
az network vnet create --address-prefixes 10.10.0.0/16 -n spoke1east -g $rg -l $loc1 --subnet-name app --subnet-prefixes 10.10.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke2east $WHITE"
az network vnet create --address-prefixes 10.11.0.0/16 -n spoke2east -g $rg -l $loc1 --subnet-name app --subnet-prefixes 10.11.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke3east $WHITE"
az network vnet create --address-prefixes 10.12.0.0/16 -n spoke3east -g $rg -l $loc1 --subnet-name app --subnet-prefixes 10.12.0.0/24 -o none

# WEST SPOKES
# create nva virtual network
echo -e "$WHITE$(date +"%T")$GREEN Creating Virtual Network nvaWestVnet $WHITE"
az network vnet create --address-prefixes 10.2.0.0/16 -n nvaWestVnet -g $rg -l $loc2 --subnet-name internal --subnet-prefixes 10.2.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating subnets $WHITE"
echo ".... creating external"
az network vnet subnet create -g $rg --vnet-name nvaWestVnet -n external --address-prefixes 10.2.1.0/24 -o none

# create spoke virtual network
echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke1west $WHITE"
az network vnet create --address-prefixes 10.20.0.0/16 -n spoke1west -g $rg -l $loc2 --subnet-name app --subnet-prefixes 10.20.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke2west $WHITE"
az network vnet create --address-prefixes 10.21.0.0/16 -n spoke2west -g $rg -l $loc2 --subnet-name app --subnet-prefixes 10.21.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating Spoke3west $WHITE"
az network vnet create --address-prefixes 10.22.0.0/16 -n spoke3west -g $rg -l $loc2 --subnet-name app --subnet-prefixes 10.22.0.0/24 -o none

# create indirect spokes
echo -e "$WHITE$(date +"%T")$GREEN Creating indirect spoke indirect1EastVnet $WHITE"
az network vnet create --address-prefixes 192.168.1.0/24 -n indirect1EastVnet -g $rg -l $loc1 --subnet-name app --subnet-prefixes 192.168.1.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating indirect spoke indirect2EastVnet $WHITE"
az network vnet create --address-prefixes 192.168.2.0/24 -n indirect2EastVnet -g $rg -l $loc1 --subnet-name app --subnet-prefixes 192.168.2.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating indirect spoke indirect1WestVnet $WHITE"
az network vnet create --address-prefixes 192.168.3.0/24 -n indirect1WestVnet -g $rg -l $loc2 --subnet-name app --subnet-prefixes 192.168.3.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating indirect spoke indirect2WestVnet $WHITE"
az network vnet create --address-prefixes 192.168.4.0/24 -n indirect2WestVnet -g $rg -l $loc2 --subnet-name app --subnet-prefixes 192.168.4.0/24 -o none

# Create remote VPN network
echo -e "$WHITE$(date +"%T")$GREEN Creating Virtual Network remoteEast $WHITE"
az network vnet create --address-prefixes 10.100.0.0/16 -n remoteEast -g $rg -l $loc1 --subnet-name app --subnet-prefixes 10.100.0.0/24 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating Virtual Network remoteWest $WHITE"
az network vnet create --address-prefixes 10.200.0.0/16 -n remoteWest -g $rg -l $loc2 --subnet-name app --subnet-prefixes 10.200.0.0/24 -o none

# Create NSG's
echo -e "$WHITE$(date +"%T")$GREEN Creating Subnet level NSG's for each location $WHITE"
mypip=$(curl -4 -s ifconfig.io)
az network nsg create -g $rg --name default-nsg-$loc1 -l $loc1 -o none
az network nsg create -g $rg --name default-nsg-$loc2 -l $loc2 -o none
# Adding my home public IP to NSG for SSH access
az network nsg rule create -g $rg --nsg-name default-nsg-$loc1 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none
az network nsg rule create -g $rg --nsg-name default-nsg-$loc2 -n 'default-allow-ssh' --direction Inbound --priority 100 --source-address-prefixes $mypip --source-port-ranges '*' --destination-address-prefixes '*' --destination-port-ranges 22 --access Allow --protocol Tcp --description "Allow inbound SSH" --output none
# Associating NSG to the VNET subnets (Spokes and Branches)
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?contains(location,`'$loc1'`)].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$loc1 -o none
az network vnet subnet update --id $(az network vnet list -g $rg --query '[?contains(location,`'$loc2'`)].{id:subnets[0].id}' -o tsv) --network-security-group default-nsg-$loc2 -o none
az network vnet subnet update --id $(az network vnet show -g $rg -n nvaEastVnet --query 'subnets[0].id' -o tsv) --network-security-group default-nsg-$loc1 -o none
az network vnet subnet update --id $(az network vnet show -g $rg -n nvaWestVnet --query 'subnets[0].id' -o tsv) --network-security-group default-nsg-$loc2 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating subnets $WHITE"
echo ".... creating GatewaySubnet"
az network vnet subnet create -g $rg --vnet-name remoteEast -n GatewaySubnet --address-prefixes 10.100.1.0/26 -o none

echo -e "$WHITE$(date +"%T")$GREEN Creating subnets $WHITE"
echo ".... creating GatewaySubnet"
az network vnet subnet create -g $rg --vnet-name remoteWest -n GatewaySubnet --address-prefixes 10.200.1.0/26 -o none

# Create remote VPN Gateways
echo -e "$WHITE$(date +"%T")$GREEN Creating remoteEast VPN GW (no-wait) $WHITE"
az network public-ip create -n remoteEastGW-pip -g $rg --location $loc1 --sku Standard -o none --only-show-errors
az network vnet-gateway create -n remoteEastGW --public-ip-addresses remoteEastGW-pip -g $rg --vnet remoteEast --asn 65510 --gateway-type Vpn -l $loc1 --sku VpnGw2 --vpn-gateway-generation Generation2 --no-wait
echo -e "$WHITE$(date +"%T")$GREEN Creating remoteWest VPN GW (no-wait) $WHITE"
az network public-ip create -n remoteWestGW-pip -g $rg --location $loc2 --sku Standard -o none --only-show-errors
az network vnet-gateway create -n remoteWestGW --public-ip-addresses remoteWestGW-pip -g $rg --vnet remoteWest --asn 65509 --gateway-type Vpn -l $loc2 --sku VpnGw2 --vpn-gateway-generation Generation2 --no-wait

if [ $useexr = 'true' ]; then
    # create er gateways in each vhub
    echo -e "$WHITE$(date +"%T")$GREEN Creating East Hub ER GW $WHITE"
    az network express-route gateway create -n hubeaster230498234 -g $rg --location $loc1 --virtual-hub hubeast -o none
    echo -e "$WHITE$(date +"%T")$GREEN Creating West Hub ER GW $WHITE"
    az network express-route gateway create -n hubwester239847234 -g $rg --location $loc2 --virtual-hub hubwest -o none

    # create er circuits
    echo -e "$WHITE$(date +"%T")$GREEN Creating East ER Circuit $WHITE"
    az network express-route create -g $rg -n exr-eastcircuit --bandwidth '50 Mbps' --peering-location "Washington DC" --provider "Megaport" -l $loc1 --sku-family MeteredData --sku-tier Standard -o none
    echo -e "$WHITE$(date +"%T")$GREEN Creating West ER Circuit $WHITE"
    az network express-route create -g $rg -n exr-westcircuit --bandwidth '50 Mbps' --peering-location "Silicon Valley" --provider "Megaport" -l $loc2 --sku-family MeteredData --sku-tier Standard -o none
fi

# Connect spokes to vHub
echo -e "$WHITE$(date +"%T")$GREEN Connect Vnets to Hub $WHITE"
echo ".... creating nvaEastVnet"
az network vhub connection create -n nvaeasttohub --remote-vnet nvaEastVnet -g $rg \
    --vhub-name hubeast \
    --route-name hubeast-indirect-rt \
    --address-prefixes 192.168.1.0/24 192.168.2.0/24 \
    --next-hop $nvaipeast \
    --only-show-errors \
    -o none
echo ".... creating spoke1EastVnet"
az network vhub connection create -n spoke1easttohub --remote-vnet spoke1east -g $rg --vhub-name hubeast -o none
echo ".... creating spoke2EastVnet"
az network vhub connection create -n spoke2easttohub --remote-vnet spoke2east -g $rg --vhub-name hubeast -o none
echo ".... creating spoke3EastVnet"
az network vhub connection create -n spoke3easttohub --remote-vnet spoke3east -g $rg --vhub-name hubeast -o none

echo ".... creating nvaWestVnet"
az network vhub connection create -n nvawesttohub --remote-vnet nvaWestVnet -g $rg \
    --vhub-name hubwest \
    --route-name hubwest-indirect-rt \
    --address-prefixes 192.168.3.0/24 192.168.4.0/24 \
    --next-hop $nvaipwest \
    --only-show-errors \
    -o none
echo ".... creating spoke1WestVnet"
az network vhub connection create -n spoke1westtohub --remote-vnet spoke1west -g $rg --vhub-name hubwest -o none
echo ".... creating spoke2WestVnet"
az network vhub connection create -n spoke2westtohub --remote-vnet spoke2west -g $rg --vhub-name hubwest -o none
echo ".... creating spoke3WestVnet"
az network vhub connection create -n spoke3westtohub --remote-vnet spoke3west -g $rg --vhub-name hubwest -o none

# connect indirect spokes to NVA vnet
VNet1Id=$(az network vnet show -g $rg -n nvaEastVnet --query id -o tsv)
VNet2Id=$(az network vnet show -g $rg -n indirect1EastVnet --query id -o tsv)
az network vnet peering create -n "indirect1EastTOnvaeastvnet" -g $rg --vnet-name nvaEastVnet --remote-vnet $VNet2Id --allow-vnet-access --allow-forwarded-traffic -o none
az network vnet peering create -n "nvaeastvnetTOindirect1East" -g $rg --vnet-name indirect1EastVnet --remote-vnet $VNet1Id --allow-vnet-access --allow-forwarded-traffic -o none

VNet2Id=$(az network vnet show -g $rg -n indirect2EastVnet --query id -o tsv)
az network vnet peering create -n "indirect2EastTOnvaeastvnet" -g $rg --vnet-name nvaEastVnet --remote-vnet $VNet2Id --allow-vnet-access --allow-forwarded-traffic -o none
az network vnet peering create -n "nvaeastvnetTOindirect2East" -g $rg --vnet-name indirect2EastVnet --remote-vnet $VNet1Id --allow-vnet-access --allow-forwarded-traffic -o none

VNet1Id=$(az network vnet show -g $rg -n nvaWestVnet --query id -o tsv)
VNet2Id=$(az network vnet show -g $rg -n indirect1WestVnet --query id -o tsv)
az network vnet peering create -n "indirect1WestTOnvaWestvnet" -g $rg --vnet-name nvaWestVnet --remote-vnet $VNet2Id --allow-vnet-access --allow-forwarded-traffic -o none
az network vnet peering create -n "nvaWestvnetTOindirect1West" -g $rg --vnet-name indirect1WestVnet --remote-vnet $VNet1Id --allow-vnet-access --allow-forwarded-traffic -o none

VNet2Id=$(az network vnet show -g $rg -n indirect2WestVnet --query id -o tsv)
az network vnet peering create -n "indirect2WestTOnvaWestvnet" -g $rg --vnet-name nvaWestVnet --remote-vnet $VNet2Id --allow-vnet-access --allow-forwarded-traffic -o none
az network vnet peering create -n "nvawestvnetTOindirect2West" -g $rg --vnet-name indirect2WestVnet --remote-vnet $VNet1Id --allow-vnet-access --allow-forwarded-traffic -o none

# create route table for FRR VM to reach internet in East
echo -e "$WHITE$(date +"%T")$GREEN Create Route Table for East NVA to Internet $WHITE"
az network route-table create -g $rg -n nvaeastroute -l $loc1 -o none
az network route-table route create -g $rg --route-table-name nvaeastroute -n tointernet \
    --next-hop-type Internet --address-prefix 0.0.0.0/0 -o none
az network vnet subnet update -g $rg -n external --vnet-name nvaEastVnet --route-table nvaeastroute -o none

# create route table for FRR VM to reach internet in West
echo -e "$WHITE$(date +"%T")$GREEN Create Route Table for West NVA to Internet $WHITE"
az network route-table create -g $rg -n nvawestroute -l $loc2 -o none
az network route-table route create -g $rg --route-table-name nvawestroute -n tointernet \
    --next-hop-type Internet --address-prefix 0.0.0.0/0 -o none
az network vnet subnet update -g $rg -n external --vnet-name nvaWestVnet --route-table nvawestroute -o none

# create NVA East
echo -e "$WHITE$(date +"%T")$GREEN Creating frr VM East $WHITE"
az network public-ip create -n $nva1"-pip" -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name nvaEastVnet --subnet internal -l $loc1 -n $nva1"IntNIC" --private-ip-address $nvaipeast --ip-forwarding true -o none
az network nic create -g $rg --vnet-name nvaEastVnet --subnet external -l $loc1 -n $nva1"ExtNIC" --public-ip-address $nva1"-pip" --private-ip-address $nvaipeastext --ip-forwarding true -o none
az vm create -n $nva1 \
    -l $loc1 \
    -g $rg \
    --image ubuntults \
    --size $vmsize \
    --nics $nva1"ExtNIC" $nva1"IntNIC" \
    --authentication-type ssh \
    --admin-username $username \
    --ssh-key-values @~/.ssh/id_rsa.pub \
    --custom-data cloud-init-east \
    -o none \
    --only-show-errors

# create NVA West
echo -e "$WHITE$(date +"%T")$GREEN Creating frr VM West $WHITE"
az network public-ip create -n $nva2"-pip" -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name nvaWestVnet --subnet internal -l $loc2 -n $nva2"IntNIC" --private-ip-address $nvaipwest --ip-forwarding true -o none
az network nic create -g $rg --vnet-name nvaWestVnet --subnet external -l $loc2 -n $nva2"ExtNIC" --public-ip-address $nva2"-pip" --private-ip-address $nvaipwestext --ip-forwarding true -o none
az vm create -n $nva2 \
    -l $loc2 \
    -g $rg \
    --image ubuntults \
    --size $vmsize \
    --nics $nva2"ExtNIC" $nva2"IntNIC" \
    --authentication-type ssh \
    --admin-username $username \
    --ssh-key-values @~/.ssh/id_rsa.pub \
    --custom-data cloud-init-west \
    -o none \
    --only-show-errors

# wait states to ensure VPN GW's are fully up
echo -e "$WHITE$(date +"%T")$GREEN Check GW provisioning states before setting up connections $WHITE"
prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n hubeast --query 'provisioningState' -o tsv)
    echo "hubeast provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n hubeast --query 'routingState' -o tsv)
    echo "hubeast routingState="$rtState
    sleep 5
done

prState=''
rtState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vhub show -g $rg -n hubwest --query 'provisioningState' -o tsv)
    echo "hubwest provisioningState="$prState
    sleep 5
done

while [[ $rtState != 'Provisioned' ]];
do
    rtState=$(az network vhub show -g $rg -n hubwest --query 'routingState' -o tsv)
    echo "hubwest routingState="$rtState
    sleep 5
done

prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vnet-gateway show -g $rg -n remoteEastGW --query provisioningState -o tsv)
    echo "remoteEastGW provisioningState="$prState
    sleep 5
done

prState=''
while [[ $prState != 'Succeeded' ]];
do
    prState=$(az network vnet-gateway show -g $rg -n remoteWestGW --query provisioningState -o tsv)
    echo "remoteWestGW provisioningState="$prState
    sleep 5
done

#
# get bgp peering and public ip addresses of VPN GW and VWAN to set up connection
echo -e "$WHITE$(date +"%T")$GREEN Get public ip's and bgp peers $WHITE"
bgpeast1=$(az network vnet-gateway show -n remoteEastGW -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
pipeast1=$(az network vnet-gateway show -n remoteEastGW -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanbgpeast1=$(az network vpn-gateway show -n hubeastvpn -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
vwanpipeast1=$(az network vpn-gateway show -n hubeastvpn -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)

bgpwest1=$(az network vnet-gateway show -n remoteWestGW -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
pipwest1=$(az network vnet-gateway show -n remoteWestGW -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)
vwanbgpwest1=$(az network vpn-gateway show -n hubwestvpn -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].defaultBgpIpAddresses[0]' -o tsv)
vwanpipwest1=$(az network vpn-gateway show -n hubwestvpn -g $rg --query 'bgpSettings.bgpPeeringAddresses[0].tunnelIpAddresses[0]' -o tsv)

# create virtual wan vpn site
echo -e "$WHITE$(date +"%T")$GREEN Create VPN site East $WHITE"
az network vpn-site create --ip-address $pipeast1 -n site-east-1 -g $rg --asn 65510 --bgp-peering-address $bgpeast1 -l $loc1 --virtual-wan vwannva --device-model 'Azure' --device-vendor 'Microsoft' --link-speed '50' --with-link true -o none
echo -e "$WHITE$(date +"%T")$GREEN Create VPN site West $WHITE"
az network vpn-site create --ip-address $pipwest1 -n site-west-1 -g $rg --asn 65509 --bgp-peering-address $bgpwest1 -l $loc2 --virtual-wan vwannva --device-model 'Azure' --device-vendor 'Microsoft' --link-speed '50' --with-link true -o none

# create virtual wan vpn connection
echo -e "$WHITE$(date +"%T")$GREEN Create VPN GW Connection East $WHITE"
az network vpn-gateway connection create --gateway-name hubeastvpn -n site-east-1-conn -g $rg --enable-bgp true --remote-vpn-site site-east-1 --internet-security --shared-key 'abc123' -o none
echo -e "$WHITE$(date +"%T")$GREEN Create VPN GW Connection West $WHITE"
az network vpn-gateway connection create --gateway-name hubwestvpn -n site-east-2-conn -g $rg --enable-bgp true --remote-vpn-site site-west-1 --internet-security --shared-key 'abc123' -o none

# create connection from vpn gw to local gateway and watch for connection succeeded
echo -e "$WHITE$(date +"%T")$GREEN Create remote VPN GW Connection East $WHITE"
az network local-gateway create -g $rg -n site-east-LG --gateway-ip-address $vwanpipeast1 --asn 65515 --bgp-peering-address $vwanbgpeast1 -l $loc1 -o none
az network vpn-connection create -n brancheasttositeeast -g $rg -l $loc1 --vnet-gateway1 remoteEastGW --local-gateway2 site-east-LG --enable-bgp --shared-key 'abc123' -o none

echo -e "$WHITE$(date +"%T")$GREEN Create remote VPN GW Connection West $WHITE"
az network local-gateway create -g $rg -n site-west-LG --gateway-ip-address $vwanpipwest1 --asn 65515 --bgp-peering-address $vwanbgpwest1 -l $loc2 -o none
az network vpn-connection create -n branchwesttositewest -g $rg -l $loc2 --vnet-gateway1 remoteWestGW --local-gateway2 site-west-LG --enable-bgp --shared-key 'abc123' -o none

# set-up routing table -- force indirect spokes East/West to NVA IP
echo -e "$WHITE$(date +"%T")$GREEN Create UDR to force tunnel indirect spokes to NVA (East) $WHITE"
az network route-table create -n RTEast-to-NVA  -g $rg -l $loc1 --disable-bgp-route-propagation true --output none
az network route-table route create -g $rg -n Rfc-to-NVA --route-table-name RTEast-to-NVA \
--address-prefix 10.0.0.0/8 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvaipeast \
--output none

## Associate route tables to vnets
az network vnet subnet update -n app -g $rg --vnet-name indirect1EastVnet --route-table RTEast-to-NVA --output none
az network vnet subnet update -n app -g $rg --vnet-name indirect2EastVnet --route-table RTEast-to-NVA --output none

echo -e "$WHITE$(date +"%T")$GREEN Create UDR to force tunnel indirect spokes to NVA (West) $WHITE"
az network route-table create -n RTWest-to-NVA  -g $rg -l $loc2 --disable-bgp-route-propagation true --output none
az network route-table route create -g $rg -n Rfc-to-NVA --route-table-name RTWest-to-NVA \
--address-prefix 10.0.0.0/8 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $nvaipwest \
--output none

## Associate route tables to vnets
az network vnet subnet update -n app -g $rg --vnet-name indirect1WestVnet --route-table RTWest-to-NVA --output none
az network vnet subnet update -n app -g $rg --vnet-name indirect2WestVnet --route-table RTWest-to-NVA --output none

# Update hub default route table to send traffic to indirect spokes
echo -e "$WHITE$(date +"%T")$GREEN Update hub default route table to redirect to indirect (East) $WHITE"
az network vhub route-table route add --destination-type CIDR -g $rg \
 --destinations 192.168.1.0/24 192.168.2.0/24 \
 --name defaultroutetable \
 --next-hop-type ResourceID \
 --next-hop $(az network vhub connection show -n nvaeasttohub --resource-group $rg --vhub-name hubeast --query id -o tsv) \
 --vhub-name hubeast \
 --route-name defeast-to-indirecteast \
 --output none

echo -e "$WHITE$(date +"%T")$GREEN Update hub default route table to redirect to indirect (East-West) $WHITE"
az network vhub route-table route add --destination-type CIDR -g $rg \
 --destinations 192.168.3.0/24 192.168.4.0/24 \
 --name defaultroutetable \
 --next-hop-type ResourceID \
 --next-hop $(az network vhub connection show -n nvawesttohub --resource-group $rg --vhub-name hubwest --query id -o tsv) \
 --vhub-name hubeast \
 --route-name defeast-to-indirectwest \
 --output none

echo -e "$WHITE$(date +"%T")$GREEN Update hub default route table to redirect to indirect (West) $WHITE"
# Update hub default route table to send traffic to indirect spokes
az network vhub route-table route add --destination-type CIDR -g $rg \
 --destinations 192.168.3.0/24 192.168.4.0/24 \
 --name defaultroutetable \
 --next-hop-type ResourceID \
 --next-hop $(az network vhub connection show -n nvawesttohub --resource-group $rg --vhub-name hubWest --query id -o tsv) \
 --vhub-name hubwest \
 --route-name defwest-to-indirectwest \
 --output none

echo -e "$WHITE$(date +"%T")$GREEN Update hub default route table to redirect to indirect (West-East) $WHITE"
az network vhub route-table route add --destination-type CIDR -g $rg \
 --destinations 192.168.1.0/24 192.168.2.0/24 \
 --name defaultroutetable \
 --next-hop-type ResourceID \
 --next-hop $(az network vhub connection show -n nvaeasttohub --resource-group $rg --vhub-name hubeast --query id -o tsv) \
 --vhub-name hubwest \
 --route-name defwest-to-indirecteast \
 --output none

# create some VM's
echo -e "$WHITE$(date +"%T")$GREEN Create remoteEastVM $WHITE"
az network public-ip create -n remoteEastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name remoteEast --subnet app -l $loc1 -n remoteEastVMNIC --public-ip-address remoteEastVM-pip -o none
az vm create -n remoteEastVM -g $rg --image ubuntults --size $vmsize -l $loc1 --nics remoteEastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create remoteWestVM $WHITE"
az network public-ip create -n remoteWestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name remoteWest --subnet app -l $loc2 -n remoteWestVMNIC --public-ip-address remoteWestVM-pip -o none
az vm create -n remoteWestVM -g $rg --image ubuntults --size $vmsize -l $loc2 --nics remoteWestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke1East VM $WHITE"
az network public-ip create -n spoke1EastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke1East --subnet app -l $loc1 -n spoke1EastVMNIC --public-ip-address spoke1EastVM-pip -o none
az vm create -n spoke1EastVM -g $rg --image ubuntults --size $vmsize -l $loc1 --nics spoke1EastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke2East VM $WHITE"
az network public-ip create -n spoke2EastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke2East --subnet app -l $loc1 -n spoke2EastVMNIC --public-ip-address spoke2EastVM-pip -o none
az vm create -n spoke2EastVM -g $rg --image ubuntults --size $vmsize -l $loc1 --nics spoke2EastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke3East VM $WHITE"
az network public-ip create -n spoke3EastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke3East --subnet app -l $loc1 -n spoke3EastVMNIC --public-ip-address spoke3EastVM-pip -o none
az vm create -n spoke3EastVM  -g $rg --image ubuntults --size $vmsize -l $loc1 --nics spoke3EastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke1West VM $WHITE"
az network public-ip create -n spoke1WestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke1West --subnet app -l $loc2 -n spoke1WestVMNIC --public-ip-address spoke1WestVM-pip -o none
az vm create -n spoke1WestVM  -g $rg --image ubuntults --size $vmsize -l $loc2 --nics spoke1WestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke2West VM $WHITE"
az network public-ip create -n spoke2WestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke2West --subnet app -l $loc2 -n spoke2WestVMNIC --public-ip-address spoke2WestVM-pip -o none
az vm create -n spoke2WestVM  -g $rg --image ubuntults --size $vmsize -l $loc2 --nics spoke2WestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create spoke3West VM $WHITE"
az network public-ip create -n spoke3WestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name spoke3West --subnet app -l $loc2 -n spoke3WestVMNIC --public-ip-address spoke3WestVM-pip -o none
az vm create -n spoke3WestVM  -g $rg --image ubuntults --size $vmsize -l $loc2 --nics spoke3WestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create indirect1East VM $WHITE"
az network public-ip create -n indirect1EastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name indirect1EastVnet --subnet app -l $loc1 -n indirect1EastVMNIC --public-ip-address indirect1EastVM-pip -o none
az vm create -n indirect1EastVM  -g $rg --image ubuntults --size $vmsize -l $loc1 --nics indirect1EastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create indirect2East VM $WHITE"
az network public-ip create -n indirect2EastVM-pip -g $rg -l $loc1 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name indirect2EastVnet --subnet app -l $loc1 -n indirect2EastVMNIC --public-ip-address indirect2EastVM-pip -o none
az vm create -n indirect2EastVM  -g $rg --image ubuntults --size $vmsize -l $loc1 --nics indirect2EastVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create indirect1West VM $WHITE"
az network public-ip create -n indirect1WestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name indirect1WestVnet --subnet app -l $loc2 -n indirect1WestVMNIC --public-ip-address indirect1WestVM-pip -o none
az vm create -n indirect1WestVM  -g $rg --image ubuntults --size $vmsize -l $loc2 --nics indirect1WestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none

echo -e "$WHITE$(date +"%T")$GREEN Create indirect2West VM $WHITE"
az network public-ip create -n indirect2WestVM-pip -g $rg -l $loc2 --version IPv4 --sku Standard -o none --only-show-errors 
az network nic create -g $rg --vnet-name indirect2WestVnet --subnet app -l $loc2 -n indirect2WestVMNIC --public-ip-address indirect2WestVM-pip -o none
az vm create -n indirect2WestVM  -g $rg --image ubuntults --size $vmsize -l $loc2 --nics indirect2WestVMNIC --authentication-type ssh --admin-username $username --ssh-key-values @~/.ssh/id_rsa.pub --only-show-errors -o none
