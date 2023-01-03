#!/bin/bash

LVM_PVS="/root/.lvm-pvs.json"
LVM_LVS="/root/.lvm-lvs.json"

LVM_VOLMAP="/root/.lvm-volmap.csv"

TMPFILE_VOLDEV="/tmp/.voldev"
TMPFILE_VOLLVM="/tmp/.vollvm"

INSTANCE_ID=$( curl http://169.254.169.254/latest/meta-data/instance-id )

VGS=$( cat ${LVM_PVS} | jq -r '.[].vg_name' | sort -u | xargs )
LVS=$( cat ${LVM_LVS} | jq -r '. | keys | join(" ")' )

#
# Format PVs
#
N_PVS=$( cat $LVM_PVS | jq -r '.[].pv_name' | wc -l )
for ((j=1;j<=${N_PVS};j++)); do test -z "$(blkid /dev/nvme${j}n1)" && mkfs -t xfs -L blkvol${j} /dev/nvme${j}n1 ; done

#
# Map volume IDs to devices
#
blkid | grep 'LABEL="blkvol' | awk -F: '{print $1}' | while read d ; do
    printf "$d," ; nvme id-ctrl -v $d -o json | jq -r '.sn' | sed 's/vol/vol-/'
done | awk -F, '{print $2","$1}' | sort > $TMPFILE_VOLDEV

#
# Map volume IDs to LVM logical volumes
#
aws ec2 describe-volumes --region eu-west-1 --filters Name=attachment.instance-id,Values=${INSTANCE_ID} | jq '
    .Volumes[] | select(.Tags[].Key == "VG") |
    {
        id: .VolumeId,
        vg: (.Tags[] | if .Key == "VG" then .Value else empty end),
        pv: (.Tags[] | if .Key == "PV" then .Value else empty end)
    }' | jq -r 'map(.) | join(",")' | sort > $TMPFILE_VOLLVM

paste -d, $TMPFILE_VOLDEV $TMPFILE_VOLLVM > $LVM_VOLMAP

#
# Create PVs
#
cat $LVM_VOLMAP | awk -F, '{print $2}' | xargs pvcreate -y

#
# Create VGs
#
echo $VGS | xargs -n 1 | while read vg ; do
    vgcreate $vg $( cat $LVM_VOLMAP | grep ",${vg}," | awk -F, '{print $2}' | xargs )
done

#
# Create LVs, format xfs, mount filesystem
#

cat $LVM_LVS | jq -r '. | to_entries[] | .key + " " + (.value | map(.) | join(" "))' |
    while read lv fstype size mount_point stripe_size stripes vg ; do
        [[ $stripes != "-" ]] && STRIPE_OPT="-i ${stripes} -I ${stripe_size}" || STRIPE_OPT=""
        [[ $size == *"%"* ]] && SIZE_OPT="-l ${size}" || SIZE_OPT="-L ${size}"
        lvcreate ${SIZE_OPT} ${STRIPE_OPT} -n ${lv} ${vg}
        test -z "$(blkid /dev/${vg}/${lv})" && mkfs -t ${fstype} -L ${lv} /dev/${vg}/${lv}
        UUID=$( blkid | grep LABEL=\"${lv}\" | awk '{print $3}' | xargs )
        echo "${UUID}  ${mount_point}  ${fstype}  defaults  0  2" >> /etc/fstab
        [ -d ${mount_point} ] || mkdir -p ${mount_point}
    done
mount -a
