#!/bin/bash
help() {
    echo "Usage:"
    echo "run_command_on_multiple_items.sh -p PROJECT_ID -e ENVIRONMENT -c domain:add -d 'domain1.com,domain2.com,domain3.com'"
    echo "run_command_on_multiple_items.sh -p PROJECT_ID -e ENVIRONMENT -c domain:delete -d 'domain1.com,domain2.com,domain3.com'"
    echo " "
    echo "run_command_on_multiple_items.sh -p PROJECT_ID -e ENVIRONMENT -c user:delete -d 'user1@domain.com,user2@domain.com'"
    exit 0
}

cancel_all_activities() {
    for activity_id in $(platform activities -p $PROJECT_ID --all --columns ID,State --limit 20 --format csv --no-header | grep "pending" | cut -d, -f1); do
        echo "Cancelling $activity_id"
        platform p:curl -XPOST /environments/$ENVIRONMENT/activities/$activity_id/cancel -p $PROJECT_ID
    done

}

run_command() {
    arr_items=($(echo $1 | tr "," "\n"))

    for item in "${arr_items[@]}"
    do
        echo "$COMMAND $item"
        platform $COMMAND -p $PROJECT_ID $item --no-wait --yes
    done
}


while getopts p:e:r:d:c: option
do
case "${option}"
in
p) PROJECT_ID=${OPTARG};;
e) ENVIRONMENT=${OPTARG};;
d) ITEMS=${OPTARG};;
c) COMMAND=${OPTARG};;

esac
done

if [ "$PROJECT_ID" = "" ]; then
    help
fi

if [ "$ENVIRONMENT" = "" ]; then
    help
fi

if [ "$COMMAND" = "" ]; then
    help
fi

if [ "$ITEMS" = "" ]; then
    help
fi


run_command $ITEMS
cancel_all_activities
platform redeploy -p $PROJECT_ID -e $ENVIRONMENT --yes
