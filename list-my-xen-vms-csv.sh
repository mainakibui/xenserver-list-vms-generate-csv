#!/bin/bash
##################################################################################################
##How to use##
#1.Upload it to Xenserver compute node
#2.Give appropriate permissions chmod u+x list-my-xen-vms.sh
#3.Run ./list-my-xen-vms-csv.sh (to print to screen)
#OR
#3.Run ./list-my-xen-vms-csv.sh > myexisting-vm-list.csv (to print to myexisting-vm-list.csv text file in current script location)
#Original script by: Scott Francis Crucial Cloud Hosting - 08/02/2013
#Updated script by: Kibui Kenneth utafitini.com/home/user/mainakibui - 01/dec/2015
####################################################################################################

#Find a HV name-label
hv_name=`/opt/xensource/bin/xe host-list params=name-label|grep name-label|cut -c 23-|head -n1`

echo "Host|UUID|VM Name|Power State|Operating System|vCPU Count|Memory(MB)|Networks|VLANS|Disk Size(GB) and Disk SR"

#Find all VMs which are not a Control Domain
list=`/opt/xensource/bin/xe vm-list params=uuid is-control-domain=false|grep "uuid"|cut -c 17-`
list=$(echo $list | tr ' ' '\n' | sort -nu)

#Loop through each VM and
for i in $list
do
  vm_name=`/opt/xensource/bin/xe vm-list params=name-label uuid=$i|grep "name-label"|cut -c 23-`
  power_state=`/opt/xensource/bin/xe vm-list params=power-state uuid=$i|grep "power-state"|cut -c 23-`
  os_version=`/opt/xensource/bin/xe vm-list params=os-version uuid=$i|grep "os-version"|cut -c 29-`
  VCPUs_number=`/opt/xensource/bin/xe vm-list params=VCPUs-number uuid=$i|grep "VCPUs-number"|cut -c 25-`
  memory=`/opt/xensource/bin/xe vm-list params=memory-static-max uuid=$i|grep "memory-static-max"|cut -c 30-`
  networks=`/opt/xensource/bin/xe vm-list params=networks uuid=$i|grep "networks"|cut -c 21-`

  #Clear concatenated VLAN Variable for the next loop
  concat_vlans=

  #Loop through the VM interfaces and find the VLAN associated with its Network
  array2=`/opt/xensource/bin/xe vif-list vm-uuid=$i|grep "network-uuid"|cut -c 25-`
  for a in $array2
  do
    vlan_number=`/opt/xensource/bin/xe pif-list network-uuid=$a host-name-label=$hv_name params=VLAN|cut -c 17-`
    concat_vlans=${concat_vlans}"~"$vlan_number
    #echo "|$vlan_number"
  done

  #Clear concatenated Disk Variable for the next loop
  concat_disks=

  #Loop though the VM disks and find SR name and Size allocation
  array3=`/opt/xensource/bin/xe vbd-list vm-uuid=$i type=Disk params=vdi-uuid|grep "vdi-uuid"|cut -c 21-`
  for b in $array3
  do
    disk_size=`/opt/xensource/bin/xe vdi-list uuid=$b params=physical-utilisation|grep "physical-utilisation"|cut -c 33-`
    disk_size_calc=$(($disk_size/1024/1024/1024))
    sr_name=`/opt/xensource/bin/xe vdi-list  uuid=$b params=sr-name-label|grep "sr-name-label"|cut -c 26-`
    disk_size_sr="$disk_size_calc GB $sr_name"
    concat_disks=${concat_disks}" "$disk_size_sr
  done

  #Convert memory to MB
  mem_calc=$(($memory/1024/1024))

  #Print a pipe delimited row for the information
  echo "'$hv_name'|'$i'|'$vm_name'|'$power_state'|'$os_version'|'$VCPUs_number'|'$mem_calc'|'$networks'|'$concat_vlans'|'$concat_disks'"
done
