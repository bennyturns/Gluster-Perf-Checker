#!/bin/bash

# Tuned profile
tune_profile=$(tuned-adm list)
if [ $? -eq 1 ]; then
    echo "Tuned is not installed or working, please check for tuned RPM"
else
    echo "Current tuned profile:"
    tuned-adm list | grep "active profile"
    if [ $? -ne 0 ]; then
        echo "Warning!  Tuned profile not found"
    fi
    echo ""
fi

# Check extent size
echo "Checking PE size of devices"
IFS=$'\n' 
pv_out=$(pvdisplay)
for line in $pv_out; do
    echo $line | grep -i "pv name" &> /dev/null
    if [ $? -eq 0 ]; then
        echo "Device:"
        echo $line #| cut -d " " -f 1
    fi
    echo $line | grep -i "pe size" &> /dev/null
    if [ $? -eq 0 ]; then
        #echo "PE size:"
        echo $line #| cut -d " " -f 1
    fi
done
echo "Devices create with commands:"
grep physicalextentsize /etc/lvm/archive/*
if [ $? -ne 0 ]; then
    echo "Warning!  No extent tuning found!"
fi

# Check chunk size
echo ""
echo "Checking chunksize of LVs"
echo "Devices created with:"
grep chunksize /etc/lvm/archive/*
if [ $? -ne 0 ]; then
    echo "Warning!  No chunksize tuning found!"
fi

# Checking current shcedulers
echo ""
echo "Checking scheduler"
dev_list=$(ls /sys/block)
unset IFS
for x in $dev_list
do
    echo $x | grep "dm" &> /dev/null
    if [ $? -eq 1 ]; then
        echo "Scheduler for ${x} -> $(cat /sys/block/${x}/queue/scheduler)"
        echo "Alignment value for ${x} -> $(cat /sys/block/${x}/alignment_offset)"
    fi
done

# MTU of NIC
echo ""
echo "Checking MTU of NICs:"
ip addr show | grep mtu

# Check volume options
echo ""
echo "Checking gluster volume options"
IFS=$'\n'
options="false"
volumes=$(gluster volume list)
for volume in $volumes; do
    echo "Volume settings for ${volume}:"
    g_v_info=$(gluster volume info ${volume})
    for line in $g_v_info; do
        echo $line | grep -i "reconfigured" &> /dev/null
        if [ $? -eq 0 ]; then
            options=true
        elif [ $options == "true" ]; then
            echo $line
        fi
    done
    options="false"
done

# Gather perf CPU stats
echo ""
rpm -q perf &> /dev/null
if [ $? -ne 0 ]; then
    echo "Perf RPM not found, cannot run perf stats."
else
    echo "Gathering 10 second sample of CPU stats"
    perf stat -a -- sleep 10
fi

# Gather memory information
echo""
echo "Memory info:"
cat /proc/meminfo

# Gather NW stats
echo ""
echo "NW info:"
ifconfig -a
