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
    IFS=','; arr_items=($1); unset IFS;

    for item in "${arr_items[@]}"
    do
        echo "Running command: platform $COMMAND -p $PROJECT_ID $item --no-wait --yes $EXTRA"
        platform $COMMAND -p $PROJECT_ID $item --no-wait --yes $EXTRA
    done
}


while getopts p:e:r:d:c:z: option
do
case "${option}"
in
p) PROJECT_ID=${OPTARG};;
e) ENVIRONMENT=${OPTARG};;
d) ITEMS=${OPTARG};;
c) COMMAND=${OPTARG};;
z) EXTRA=${OPTARG};;

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

if [[ "$ITEMS" == *"="* ]]; then
    # make name=value -> --name=$name --value=$value
    arr_items=($(echo "$ITEMS" | tr "," "\n"))

    ITEMS=""
    for item in "${arr_items[@]}"
    do
        # split the key=value into an array
        IFS='='; arrItem=($item); unset IFS;

        item_name="${arrItem[0]}"
        item_value="${arrItem[1]}"

        ITEMS="$ITEMS --name=$item_name --value=\"$item_value\","
    done
fi

if [ "$ITEMS" = "" ]; then
    help
fi


run_command "$ITEMS" "$KEEP_ENVIRONMENT"
cancel_all_activities
platform redeploy -p $PROJECT_ID -e $ENVIRONMENT --yes
