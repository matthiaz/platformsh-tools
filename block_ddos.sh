#!/bin/bash
#./block_ddos.sh [MAX_ALLOWED_REQUESTS] [PERIOD]
#./block_ddos.sh
#./block_ddos.sh 60
#./block_ddos.sh 60 'last minute'
#./block_ddos.sh 3600 'last hour'
#./block_ddos.sh 3600 'now -1hour'

MAX_REQUESTS=${1:-60} #if no param is given, use 1 request/sec by default
VDATE=${2:-last minute}

echo "MAX REQUESTS $MAX_REQUESTS"
echo "VDATE $VDATE"


#get the previous minute, to make grep filter on that
time_to_filter=$(date +'[%d/%b/%Y:%H:%M:%S]' --date="$VDATE")

echo "Time to filter $time_to_filter"



#get the ips that do more requests/minute than we allow
FILTERED_IPS=$(awk -vDate="$time_to_filter" '$4 > Date {print $0}' /var/log/access.log | awk '{count[$1]++}END{for(j in count) print count[j]" " j}' | sort -r | awk -v x="$MAX_REQUESTS" '{if($1 > x){print " --access deny:"$2}}' | xargs)
echo "filtered $FILTERED_IPS"


#run platform httpaccess to block ip's that appear more than x times
echo "platform httpaccess $FILTERED_IPS --access allow:any --no-wait --yes"
platform httpaccess $FILTERED_IPS --access allow:any --no-wait --yes



