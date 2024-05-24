#!/bin/bash
get_resources() {
    PROJECT_ID="$1"
    ENV="${2:-main}"
    sum_cpu=0
    sum_mem=0
    sum_disk=0

    printf "%-30s\t%s\t%s\t%s\t%s\n" "Service" "cpu" "mem" "disk"
    printf "%-30s\t%s\t%s\t%s\t%s\n" "-------" "---" "---" "----"
    echo ""
    for service in $(platform mem --columns service -1 --format csv --no-header -p $PROJECT_ID -e $ENV); do
        cpu_limit=$(platform cpu --columns limit --service=$service -1 --format csv --no-header -p $PROJECT_ID -e $ENV | tr -d '\n')
        mem_limit=$(platform mem --columns limit --service=$service -1 --format csv --no-header --bytes -p $PROJECT_ID -e $ENV | tr -d '\n')
        mem_limit=$((mem_limit / 1024 / 1024))
        disk_limit=$(platform disk --columns limit --service=$service -1 --format csv --no-header --bytes -p $PROJECT_ID -e $ENV | tr -d '\n')
        disk_limit=$((disk_limit / 1024 / 1024))

        sum_cpu=$(awk "BEGIN{print $cpu_limit + $sum_cpu}")
        sum_mem=$((mem_limit + sum_mem))
        sum_disk=$((disk_limit + sum_disk))
        printf "%-30s\t%2.2f\t%s\t%s\t%s\n" $service $cpu_limit $mem_limit $disk_limit
    done
    echo " "
    printf "%-30s\t%s\t%s\t%s\t%s\n" "-------" "---" "---" "----"
    printf "%-30s\t%2.2f\t%s\t%s\t%s\n" "Total" $sum_cpu $sum_mem $sum_disk

    echo "Plan:"
    platform project:info subscription -p $PROJECT_ID | grep -e 'plan:' -e production | sed -e 's/medium/max_cpu: 2.09, max_memory: 3072/g'

}
get_resources "$1" "$2"
