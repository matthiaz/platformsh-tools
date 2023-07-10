#!/bin/bash
int(){ printf '%d' ${1:-} 2>/dev/null || :; }
abuseipconfidence() {
    curl -SsG https://api.abuseipdb.com/api/v2/check \
  --data-urlencode "ipAddress=$1" \
  -d maxAgeInDays=90 \
  -d verbose \
  -H "Key: $ABUSEIP_TOKEN" \
  -H "Accept: application/json" | jq .data.abuseConfidenceScore
}
if [[ -z "${DEPLOY_ENV}" ]]; then
    echo "please ensure you have a ABUSEIP_TOKEN to be able to check IP abuse"
    exit 4
fi

WORKER_COUNT=$(cat /etc/php*/*/fpm/php-fpm.conf | grep children | cut -d'=' -f2 | xargs)
CURRENT_WORKERS_IN_USE=$(ps auxf | grep php-fpm | grep pool | wc -l | xargs)
REQUEST_AVG_MEMORY=$(tail -n1000 /var/log/php.access.log | strings | awk '{ total += $6; count++ } END { print int(total/count/1024+0.5) }')
REQUEST_MAX_MEMORY=$(tail -n1000 /var/log/php.access.log | strings | awk '{print int($6/1024+0.5)}' | sort | head -n 1)
TOTAL_CONTAINER_RESERVED_MEMORY=$(cat /run/config.json | jq -r .info.limits.memory)
CONTAINER_RESERVED_MEMORY=70

PHP_MEMORY_LIMIT=$(int $(php -i | grep memory_limit | cut -d'>' -f3 | xargs))
NGINX_GATEWAY_ERRORS=$(grep -Fa "$(date +%Y/%m/%d)" /var/log/error.log | grep -e "Resource temporarily unavailable" -e "Connection reset by peer" -e "upstream prematurely closed FastCGI request while reading upstream" | wc -l)
MIN_NGINX_GATEWAY_ERRORS=2

LOWEST_POSSIBLE_REQUEST_HINT=$(($REQUEST_AVG_MEMORY + $REQUEST_MAX_MEMORY))
MAX_POSSIBLE_WORKER_COUNT=$(( ($TOTAL_CONTAINER_RESERVED_MEMORY-$CONTAINER_RESERVED_MEMORY) / $LOWEST_POSSIBLE_REQUEST_HINT))
ESTIMATED_MEMORY_USAGE=$(($CONTAINER_RESERVED_MEMORY+$LOWEST_POSSIBLE_REQUEST_HINT))

SLOW_REQUESTS=$(grep -Fa "$(date +%Y-%m-%d)" /var/log/php.access.log | sort -n -k 4|tail -n 5)
HIGH_MEMORY_REQUESTS=$(grep -Fa "$(date +%Y-%m-%d)" /var/log/php.access.log | sort -n -k 6|tail -n 5)
TOP_IPS=$(tail -n1000 /var/log/access.log | awk '{print $1}' | sort | uniq -c | sort -nr | head -n5)

echo " "
echo "# Facts"
echo "---------"
echo "PHP workers available to run requests in parallel          : $WORKER_COUNT"
echo "Current PHP workers in use                                 : $CURRENT_WORKERS_IN_USE"
echo " "
echo "Average memory usage for last 1000 requests                : $REQUEST_AVG_MEMORY MB"
echo "Highest memory usage for last 1000 requests                : $REQUEST_MAX_MEMORY MB"
echo "Container total available memory(excluding burst)          : $TOTAL_CONTAINER_RESERVED_MEMORY MB"

echo " "
echo "# Recommendation"
echo "------------------"
echo "Lowest runtime.sizing_hints.request_memory possible        : $LOWEST_POSSIBLE_REQUEST_HINT MB"
echo "Theoretical worker count                                   : $MAX_POSSIBLE_WORKER_COUNT"

echo " "
echo "# Log analysis"
echo "--------------"
echo "Slowest PHP requests in /var/log/php.access.log (today):"
echo "$SLOW_REQUESTS"
echo " "
echo "Highest memory requests in /var/log/php.access.log (today):"
echo "$HIGH_MEMORY_REQUESTS"
echo " "
echo "Top IPs hitting the site:"
echo " hits | IP address | Abuse confidence % (higher is abusive) " 
while IFS= read -r line; do
    echo -n $line
    ip_to_check=$(echo $line | cut -d' ' -f2)
    echo " $(abuseipconfidence $ip_to_check)%"
done <<< "$TOP_IPS"


echo "$TOP_IPS"abuseipconfidence
echo " "
echo "--------------"
echo " "
echo "----------- Customer Info -----------"
# Warnings / Recommendation
if [ "$PHP_MEMORY_LIMIT" -gt "$TOTAL_CONTAINER_RESERVED_MEMORY" ]
then
    echo " "
    echo "# PHP memory limit |"
    echo " "
    echo "You have set your php.memory_limit to $PHP_MEMORY_LIMIT MB, this is larger than the current container memory of $TOTAL_CONTAINER_RESERVED_MEMORY MB!"
    echo "As a general rule, you want the php.memory_limit to be less than the container memory, currently $TOTAL_CONTAINER_RESERVED_MEMORY MB."
    echo " "
    echo "# Why is this a problem?"
    echo " "
    echo "Increasing the php.memory_limit doesn't actually give you more memory. It only tells PHP to not limit the php scripts. Usually this isn't a problem because we allow you to use more memory than you are paying for."
    echo "However, when you have a script using up a lot of memory it can run the whole container out of memory and the system Out of Memory killer will start to kill processes. Potentially taking down your site."
    echo "If you leave the memory_limit to a sensible level, high memory scripts will be stopped by PHP. They will also be reported in the 'app.log' allowing you to go in and fix the scripts in question."    
    echo " "
    echo " "
fi

# Recommendation
if [ "$NGINX_GATEWAY_ERRORS" -gt "$MIN_NGINX_GATEWAY_ERRORS" ]
then
    echo " "
    echo " "
    echo "# 502 errors |"
    echo " "
    echo "It looks like you have run out of PHP workers several times today, this might cause visitors to see a 502 Gateway error."
    if [ "$MAX_POSSIBLE_WORKER_COUNT" -gt "$WORKER_COUNT" ]
    then
        echo "Your code is efficient enough that it should be able to handle more request if we just adjust the request hints."
        echo "Please try adding this to your .platform.app.yaml file:"
        echo "
\`\`\`        
    runtime:
        sizing_hints:
            request_memory: $LOWEST_POSSIBLE_REQUEST_HINT
\`\`\`        
        "
        echo "This should increase the PHP workers from the current $WORKER_COUNT to $MAX_POSSIBLE_WORKER_COUNT workers. Allowing you to handle more visitor requests/second."
        echo " "
        echo "# What is a PHP Worker?"
        echo "PHP Workers are like a highway. You can have many fast cars on $WORKER_COUNT lanes. If you get too many cars, you can add more lanes and more cars can drive on $MAX_POSSIBLE_WORKER_COUNT lanes. However, it is important that we don't have slow trucks/slow requests on our highway. If we do, even fast cars/fast requests will be stuck behind the slow truck/slow request."
        echo "More information: https://docs.platform.sh/languages/php/fpm.html"
        
    else
        echo "Please increase your plan size to get more resource for your site"
    fi    
    echo " "
    echo "It might also be worth it to check these scripts since they consume a lot of resources"
    echo "Slowest PHP requests in /var/log/php.access.log (today):"
    echo "$SLOW_REQUESTS"
    echo " "
    echo "Highest memory requests in /var/log/php.access.log (today):"
    echo "$HIGH_MEMORY_REQUESTS"
    echo " "
    echo " "    
fi
