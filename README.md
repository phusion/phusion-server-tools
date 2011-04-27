# Phusion Server Tools

A collection of server administration tools that we use. Everything is
written in Ruby and designed to work with Debian. These scripts may
work with other operating systems or distributions as well, but it's not
tested.

Install with:

    git clone https://github.com/FooBarWidget/phusion-server-tools.git /tools

It's not necessary to install to /tools, you can install to anywhere, but this document assumes that you have installed to /tools.

Each tool has its own prerequities, but here are some common prerequities:

 * Ruby (obviously)
 * `pv` - `apt-get install pv`. Not required but very useful; allows display of progress bars.

Some tools require additional configuration through `config.yml`, which must be located in the same directory as the tool or in `/etc/phusion-server-tools.yml`. Please see `config.yml.example` for an example.


## Backup

### backup-mysql - Rotated, compressed, encrypted MySQL dumps

A script which backs up all MySQL databases to `/var/backups/mysql`. By default at most 10 backups are kept, but this can be configured. All backups are compressed with gzip and can optionally be encrypted. The backup directory is denied all world access.

It uses `mysql` to obtain a list of databases and `mysqldump` to dump the database contents. If you want to run this script unattended you should therefore set the right login information in `~/.my.cnf`, sections `[mysql]` and `[mysqldump]`.

Encryption can be configured through the 'encrypt' option in config.yml.

Make it run daily at 12:00 AM and 0:00 AM in cron:

    0 0,12 * * * /tools/silence-unless-failed /tools/backup-mysql


## Monitoring and alerting

### monitor-cpu - Monitors CPU usage and send email on suspicious activity

A daemon which measures the CPU usage every minute, and sends an email if the average usage usage over a period of time equals or exceeds a threshold.

Config options:

  * threshold: The CPU usage threshold (0%-100%) to check against.
  * interval: The interval, in minutes, over which the average is calculated.
  * to, from, subject: Configuration for the email alert.

You should run monitor-cpu with daemon tools:

    mkdir -p /etc/service/monitor-cpu
    cat <<EOF > /etc/service/monitor-cpu/run.tmp
    #!/bin/bash
    set -em
    setuidgid daemon /tools/monitor-cpu 2>&1 | setuidgid daemon logger -t monitor-cpu &
    trap "kill $(jobs -p)" EXIT
    fg %1 >/dev/null
    EOF
    chmod +x /etc/service/monitor-cpu/run.tmp
    mv /etc/service/monitor-cpu/run.tmp /etc/service/monitor-cpu/run

### notify-if-queue-becomes-large - Monitor RabbitMQ queue sizes

This script monitors all RabbitMQ queues on the localhost RabbitMQ installation and sends an email if one of them contain more messages than a defined threshold. You can configure the settings in `config.yml`.

Run it every 15 minutes in cron:

    0,15,30,45 * * * * /tools/notify-if-queue-becomes-large


## File management

### permit and deny - Easily set fine-grained permissions using ACLs

`permit` recursively gives a user access to a directory by using ACLs. The default ACL is modified too so that any new files created in that directory or in subdirectories inherit the ACL rules that allow access for the given user.

`deny` recursively removes all ACLs for a given user on a directory, including default ACLs.

The standard `setfacl` tool is too hard to use and sometimes does stupid things such as unexpectedly making files executable. These scripts are simple and work as expected.

    # Recursively give web server read-only access to /webapps/foo.
    /tools/permit www-data /webapps/foo
    
    # Recursively give user 'deploy' read-write access to /webapps/bar.
    /tools/permit deploy /webapps/bar --read-write
    
    # Recursively remove all ACLs for user 'joe' on /secrets/area66.
    /tools/deny joe /secrets/area66

You need the `getfacl` and `setfacl` commands:

    apt-get install acl

You must also make sure your filesystem is mounted with ACL support, e.g.:

    mount -o remount,acl /

Don't forget to update /etc/fstab too.

### truncate

Truncates all passed files to 0 bytes.


## RabbitMQ

### display-queue - Display statistics for local RabbitMQ queues

This tool displays statistics for RabbitMQ queues in a more friendly formatter than `rabbitmqctl list_queues`. The meanings of the columns are as follows:

 * Messages - Total number of messages in the queue. Equal to `Ready + Unack`.
 * Ready - Number of messages in the queue not yet consumed.
 * Unack - Number of messages in the queue that have been consumed, but not yet acknowledged.
 * Consumers - Number of consumers subscribed to this queue.
 * Memory - The amount of memory that RabbitMQ is using for this queue.

### watch-queue - Display changes in local RabbitMQ queues

`watch-queue` combines the `watch` tool with `display-queue`. It continuously displays the latest queue statistics and highlights changes.

### purge-queue - Remove all messages from a local RabbitMQ queue

`purge-queue` removes all messages from given given RabbitMQ queue. It connects to a RabbitMQ server on localhost on the default port. Note that consumed-but-unacknowledged messages in the queue cannot be removed.

    purge-queue <QUEUE NAME HERE>

### notify-if-queue-becomes-large - Monitor RabbitMQ queue sizes

See the related documentation under "Monitoring and alerting".


## Other

### silcence-unless-failed

Runs the given command but only print its output (both STDOUT and STDERR) if its exit code is non-zero. The script's own exit code is the same as the command's exit code.

    /tools/silence-unless-failed my-command arg1 arg2 --arg3

### gc-git-repos

Garbage collects all git repositories defined in `config.yml`. For convenience, the list of repositories to garbage collect can be a glob, e.g. `/u/apps/**/*.git`.

In order to preserve file permissions, the `git gc` command is run as the owner of the repository directory by invoking `su`. Therefore this tool must be run as root, or it must be run as the owner of all given git repositories.

Make it run every Sunday at 0:00 AM in cron with low I/O priority:

    0 0 * * sun /tools/silence-unless-failed ionice -n 7 /tools/git-gc-repos
