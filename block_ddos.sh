#!/bin/bash
#./block_ddos.sh 1
MAX_REQUESTS_PER_SECOND=${1:-1} #if no param is given, use 1 request/sec by default
MAX_REQUESTS_PER_MINUTE=$(($MAX_REQUESTS_PER_SECOND * 60))
MAX_REQUESTS_PER_HOUR=$(($MAX_REQUESTS_PER_MINUTE * 60 ))

echo "MAX REQUESTS PER SECOND $MAX_REQUESTS_PER_SECOND"
echo "MAX REQUESTS PER MINUTE $MAX_REQUESTS_PER_MINUTE"
echo "MAX REQUESTS PER HOUR $MAX_REQUESTS_PER_HOUR"


#get the previous minute, to make grep filter on that
time_to_filter=$(date +'%d/%b/%Y:%H:%M:' --date='last minute')

#if you want to have a bigger time filter, maybe use last hour like this?
#time_to_filter=$(date +'%d/%b/%Y:%H:' --date='last hour')

echo "Time to filter $time_to_filter"




#get the ips that do more requests/minute than we allow
IPS=$(cat /var/log/access.log | grep $time_to_filter | awk '{count[$1]++}END{for(j in count) print count[j]" " j}')
FILTERED_IPS=$(cat /var/log/access.log | grep $time_to_filter | awk '{count[$1]++}END{for(j in count) print count[j]" " j}' | awk -v x='$MAX_REQUESTS_PER_MINUTE' '{if($1 > x){print " --access deny:"$2}}' | xargs)
echo $IPS
echo $FILTERED_IPS


#run platform httpaccess to block ip's that appear more than x times
echo "platform httpaccess --access allow:any $FILTERED_IPS --no-wait --yes"
platform httpaccess --access allow:any $FILTERED_IPS --no-wait --yes


