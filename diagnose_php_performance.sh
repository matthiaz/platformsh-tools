#!/bin/bash
help() {
    echo "Usage:"
    echo "diagnose_php_performance.sh -p PROJECT_ID -e ENVIRONMENT"
    exit 0
}


while getopts p:e:A: option
do
case "${option}"
in
p) PROJECT_ID=${OPTARG};;
e) ENVIRONMENT=${OPTARG};;
esac
done

if [ "$PROJECT_ID" = "" ]; then
    help
fi

if [ "$ENVIRONMENT" = "" ]; then
    help
fi

APP_OR_WORKER=$(platform app:list -p "$PROJECT_ID" -e "$ENVIRONMENT" --format=csv --no-header --columns=name | sort | head -n1 | xargs)
cat php_worker_count.sh | platform ssh -p "$PROJECT_ID" -e "$ENVIRONMENT" --app "$APP_OR_WORKER"