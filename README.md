# 1. Prerequisites

Most of these tools use [platformsh-cli](https://github.com/platformsh/platformsh-cli). 

Install `platform-cli` inside your container like this: 

```
hooks:
    build: |
        curl -sS https://platform.sh/cli/installer | php
```
[Source](https://docs.platform.sh/development/cli/api-tokens.html#install-the-cli-on-a-platformsh-environment).

# 2. Installation

1. [Download the repository locally](https://github.com/matthiaz/platformsh-tools/archive/refs/heads/master.zip)
2. Copy the scripts you want to use in your project and commit them to your repository.

*You can modify any of these scripts as you like.*

# Options

## Crons

Some of these tools can be triggered [using cron scripts](https://docs.platform.sh/configuration/app/cron.html#cron-jobs).
Ensure to set the correct cron schedule. [crontab.guru](https://crontab.guru/) can be helpful. 


-------


# 3. Scripts

# a) install Packages

In this section, you will find scripts that assist you in install packages as platform.sh projects are (usually) read-only once deployed.

## Install PHP packages - `pecl`

This script can be used as a somewhat replacement to the `pecl install <package>` package manager.
[PECL](https://pecl.php.net/) is used by PHP to compile and install custom extensions.
It doesn't do search, but can compile packages just fine.

### Usage:
  
1. [Download the sourcecode](https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/pecl)
2. Place the file in your project root.  
3. Add the following as a hook:
```
hooks:
    build: |
        set -e  
        chmod +x pecl  
        ./pecl install grpc
```
  
It will automatically add a `/app/php.ini` file with the extension requested. 
The first builds will be slow since they compile the package, but subsequent builds will be [cached in `PLATFORM_CACHE_DIR` automatically](https://docs.platform.sh/create-apps/app-reference/single-runtime-image.html#writable-directories-during-build).




## Install packages with brew - `install_brew_packages.sh`

[brew.sh](https://formulae.brew.sh/formula-linux/) is a package manager specifically for macos, but it can also be used to install packages on linux.
This allows you to install all sorts of things fairly easy within in the build hook.

All you have to do is copy the [install_brew_packages.sh](https://github.com/matthiaz/platformsh-tools/blob/master/install_brew_packages.sh) file into the root of your project (where your `.platform.app.yaml` lives) and then you can call it in the build hook. 
The script takes 1 or more arguments. Specify the packages you want to install as an argument.

Building from source with `brew` is rather slow, but the script will automatically use the cache folder. 
This will ensure that the subsequent builds are fast.

### examples

To install `duf` and `lnav` you can do this:

```
hooks:
    build: |
        set -e
        bash install_brew_packages.sh duf lnav
```

# b. Block IPs

In this section, you will find scripts that assist you in block unwanted traffic, for example to avoid being DDOS-ed by aggressive crawlers or bots.

## Block IPs - `block_ddos.sh`

This script can be used to automatically block IP addresses using the `platform environment:http-access` tool.

*IMPORTANT NOTE: This will automatically redeploy your environment. *

```
#./block_ddos.sh [MAX_ALLOWED_REQUESTS=60] [PERIOD='last minute']
#./block_ddos.sh
#./block_ddos.sh 60
#./block_ddos.sh 60 'last minute'
#./block_ddos.sh 3600 'last hour'
#./block_ddos.sh 3600 'now -1hour'
```

### examples

- `bash block_ddos.sh` 
  - Looks at /var/log/access.log 
  - Blocks all IPs that were seen more than 60 times in the previous minute. 
  
- `bash block_ddos.sh 300` 
  - Looks at /var/log/access.log 
  - Blocks all IPs that were seen more than 300 times in the previous minute. 

You could run the script manually or you could put it in a cron that runs every 15 minutes or so. 

e.g.:
```
hooks:
    build: |
        curl -sS https://platform.sh/cli/installer | php
        
crons:
    blockddos:
        spec: '*/15 * * * *' #every x minutes
        cmd: |
            if [ "$PLATFORM_BRANCH" = master ]; then
                bash block_ddos.sh 1000 'now -15minutes'
            fi

```




## Ban IPs in fastly automatically - `autoban_in_fastly.sh`

This script allows you to synchronize a database table with banned IPs, with your fastly CDN
it allows you to easily ban_ips from your application.
Prerequisites:

- environment variables `FASTLY_API_TOKEN` and `FASTLY_SERVICE_ID` need to be set (should be done already but double check)
- ensure that you change `TABLE_TO_GET_IPS_FROM` in the script to the correct table name

Triggering it can be done manually

```
bash ./autoban_in_fastly
```

Or via a cron script every x minutes

```
crons:
     autoban:
         spec: '*/13 * * * *'
         commands:
             start: ./autoban_in_fastly.sh
         shutdown_timeout: 31
```



## Block AI bots by adding them to the `robots.txt` file - `add_ai_bots_to_robots_txt.sh`

The [add_ai_bots_to_robots_txt.sh](https://github.com/matthiaz/platformsh-tools/blob/master/add_ai_bots_to_robots_txt.sh) script appends known AI bots to the robots.txt and can simply be added to your build hook.

```
hooks:
    build: |
        set -e
        bash add_ai_bots_to_robots_txt.sh
```

AI is cool and all, but many of these AI bots use very aggressive crawlers that actively take down websites due to the amount of requests they send. Even if your site can handle the requests, you are paying server resources to feed them content that you created and they give nothing back. They are not search engine bots, they will not be sending traffic to your site in any way in the future.

Many customers have asked to block them. And you can, but one quick easy win is to ensure that your robots.txt file is up to date and tells them correctly not to browse your site.



# c. Configure your project

In this section, you will find scripts that assist you in configuring your project.

## Add several variables - `add_multiple_variables.sh`

This script can be used to quickly add lots of env variables without having to wait for each deploy


### examples

`git clone` the repository, 
you can then run:

```
bash add_multiple_variables.sh PROJECT_ID ENVIRONMENT_TO_REDEPLOY 'var1=val1,var2=val2,var3=val3' VARIABLE_LEVEL (project or environment=default)`
```

So, for project-level variables:
```
bash add_multiple_variables.sh xj2nccsddc57w master 'var1=val1,var2=val2,var3=val3' project
```


## Add several domains - `add_multiple_domains.sh`

This script can be used to quickly add lots of domains without having to wait for each deploy


### examples

git clone the repository, you can then run 
```
./add_multiple_domains.sh PROJECT_ID ENVIRONMENT_TO_REDEPLOY 'domain1.com,domain2.com,domain3.com'
```

Which could give something like:
```
./add_multiple_domains.sh tug2vhb33pje6 master 'test001.giveatree.world,test002.giveatree.world,test003.giveatree.world,test004.giveatree.world,test005.giveatree.world,test006.giveatree.world'
```



## Delete several domains - `delete_multiple_domains.sh`

This script can be used to quickly delete lots of domains without having to wait for each deploy


### examples

`git clone` the repository, you can then run

`./delete_multiple_domains.sh PROJECT_ID ENVIRONMENT_TO_REDEPLOY 'domain1.com,domain2.com,domain3.com'

`./delete_multiple_domains.sh tug2vhb33pje6 master 'test001.giveatree.world,test002.giveatree.world,test003.giveatree.world,test004.giveatree.world,test005.giveatree.world,test006.giveatree.world'`




## Delete several users - `delete_multiple_users.sh`

This script can be used to quickly delete lots of users without having to wait for each deploy


### examples

`git clone` the repository, you can then run

`./delete_multiple_users.sh PROJECT_ID ENVIRONMENT_TO_REDEPLOY 'user1@example.com,user2@example.com,user3@example.com'

`./delete_multiple_users.sh tug2vhb33pje6 master 'test001@giveatree.world,test002@giveatree.world,test003@giveatree.world'`




# d. Analyze bandwidth or resources

In this section, you will find scripts that assist you in analyzing the resource usage of your project. Maybe as an extension of the [PHP-FPM sizing documentation page](https://docs.platform.sh/languages/php/fpm.html#measuring-php-worker-memory-usage)

## Bandwidth statistics - `bandwith_stats.sh`

This script can be used to analyze your `access.log` and give a good estimation of how much data is being sent. This can be used to determine the right size of a CDN solution (CloudFront, Fastly,...).
It's a simple bash script and can be used without needing a `platform-cli` API key.

*NOTE: We trim log files, so only the last 100MB of log files will be parsed (usually a few days worth)*

```
#./bandwith_stats.sh
```

### examples 

`curl -L -sS https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/bandwith_stats.sh | bash` 

Or if you want to download it

`curl -L -sS --output /tmp/bandwith_stats.sh https://raw.githubusercontent.com/matthiaz/platformsh-tools/master/bandwith_stats.sh && bash /tmp/bandwith_stats.sh` 

You don't have to download it, you can simply pipe the script straight to curl as per the first example.




## Resource allocation per container - `get_resources.sh`

[get_resources.sh](https://github.com/matthiaz/platformsh-tools/blob/master/get_resources.sh) helps with diagnosing how much resources are allocated to all containers.

Usage: `get_resources.sh <projectid> <environment>`

Example:
```
bash get_resources.sh y3dnj3qm242nq master

Service                       	cpu	mem	disk	
-------                       	---	---	----	

drupal                        	0.40	128	12021	
cache                         	0.08	256	0	
db                            	0.25	288	15045	
 
-------                       	---	---	----	
Total                         	0.73	672	27066	
Plan:
    production: { legacy_development: false, max_cpu: 0.96, max_memory: 768, max_environments: 1 }
```
