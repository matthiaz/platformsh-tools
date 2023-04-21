#!/bin/bash
PROJECT_ID=$1
ENV=$2
VARIABLES=$3
LEVEL=${4:-environment}
EXTRA="--level=$LEVEL"

if [ "$LEVEL" = "environment" ]; then
    EXTRA="$EXTRA--environment=$ENV"
fi


./run_command_on_multiple_items.sh -p $PROJECT_ID -e $ENV -c variable:create -d $VARIABLES -z "$EXTRA"
