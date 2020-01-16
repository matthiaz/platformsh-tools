# platformsh-tools
## Prerequisites

Most of these tools use [platformsh-cli](https://github.com/platformsh/platformsh-cli). You can install platform-cli inside your container like this: 

https://docs.platform.sh/development/cli/api-tokens.html#install-the-cli-on-a-platformsh-environment

```
hooks:
    build: |
        curl -sS https://platform.sh/cli/installer | php
```

## Installation/Downloading.

You can download the tools by simply using curl.

e.g. Your build hook might look like this
```
hooks:
    build: |
        curl -sS https://platform.sh/cli/installer | php
        curl -sS --output block_ddos.sh https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/block_ddos.sh
```

Alternatively, check out the repository and put the code into your own repository. You can modify it as you like. 

## Crons

Some of these tools can be triggered using cron scripts as described here https://docs.platform.sh/configuration/app/cron.html#cron-jobs
Make sure you set the correct run time. https://crontab.guru/ can be of assistance. 

-------

## Scripts

### block_ddos.sh
This script can be used to automatically block ip addresses using the `platform environment:http-access` tool.

*IMPORTANT NOTE: This will automatically redeploy your environment. *

```
#./block_ddos.sh [MAX_ALLOWED_REQUESTS=60] [PERIOD='last minute']
#./block_ddos.sh
#./block_ddos.sh 60
#./block_ddos.sh 60 'last minute'
#./block_ddos.sh 3600 'last hour'
#./block_ddos.sh 3600 'now -1hour'
```

#### examples
- `bash block_ddos.sh` 
  - Looks at /var/log/access.log 
  - Blocks all IP's that were seen more than 60 times in the previous minute. 
  
- `bash block_ddos.sh 300` 
  - Looks at /var/log/access.log 
  - Blocks all IP's that were seen more than 300 times in the previous minute. 

You could run the script manually or you could put it in a cron that runs every 15 minutes or so. 

e.g.:
```
hooks:
    build: |
        curl -sS https://platform.sh/cli/installer | php
        curl -sS --output block_ddos.sh https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/block_ddos.sh
crons:
    blockddos:
        spec: '*/15 * * * *' #every x minutes
        cmd: |
            if [ "$PLATFORM_BRANCH" = master ]; then
                bash block_ddos.sh 1000 'now -15minutes'
            fi

```

-------

### bandwith_stats.sh
This script can be used to analyse your access.log and give a good estimation on how much data is being sent. This can be used to determine the right size of a CDN solution (CloudFront, Fastly,...). It is a simple bash script and can be used without needing a platform-cli API key.



*NOTE: We trim log files, so only the last 100MB of log files will be parsed (usually a few days worth)*

```
#./bandwith_stats.sh
```

#### examples 
`curl -sS https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/bandwith_stats.sh | bash` 

Or if you want to download it

`curl -sS --output /tmp/bandwith_stats.sh https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/bandwith_stats.sh && bash /tmp/bandwith_stats.sh` 

You don't have to download it, you can simply pipe the script straight to curl as per the first example.
  
-------
