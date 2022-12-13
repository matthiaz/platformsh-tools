#!/bin/bash
PROJECT_ID=$1
ENVIRONMENT=$2

help() {
    echo "Usage:"
    echo "cancel_all_activities PROJECT_ID ENVIRONMENT"
    exit 0
}

cancel_all_activities() {
    for activity_id in $(platform activities -p $PROJECT_ID --all --columns ID,State --limit 20 --format csv --no-header | grep "pending" | cut -d, -f1); do
        echo "Cancelling $activity_id"
        platform p:curl -XPOST /environments/$ENVIRONMENT/activities/$activity_id/cancel -p $PROJECT_ID
    done

}


if [ "$PROJECT_ID" = "" ]; then
    help
fi

if [ "$ENVIRONMENT" = "" ]; then
    help
fi


cancel_all_activities
