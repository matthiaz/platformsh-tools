#!/bin/bash
PROJECT_ID=$1
ENVIRONMENT=$2
DOMAINS=$3

./run_command_on_multiple_items.sh -p $PROJECT_ID -e $ENVIRONMENT -c domain:add -d $DOMAINS
