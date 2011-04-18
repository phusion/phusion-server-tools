# Phusion Server Tools

A collection of server administration tools that we use. Everything is
written in Ruby and are designed to work with Debian. These scripts may
work with other operating systems or distributions as well, but it's not
tested.

Install with:

    git clone https://github.com/FooBarWidget/phusion-server-tools.git /tools

It's not necessary to install to /tools, you can install to anywhere, but this document assumes that you have installed to /tools.

Each tool has its own prerequities, but here are some common prerequities:

 * Ruby (obviously)
 * `pv` - `apt-get install pv`. Not required but very useful; allows display of progress bars.


## Included tools

### backup-mysql - Rotating MySQL dumps

A script which backs up all MySQL databases to `/var/backups/mysql`. At most 10 backups are kept. All backups are compressed with gzip.

It uses `mysql` to obtain a list of databases and `mysqldump` to dump the database contents. If you want to run this script unattended you should therefore set the right login information in `~/.my.cnf`, sections `[mysql]` and `[mysqldump]`.

Make it run daily at 0:00 AM in cron:

    0 0 * * * /tools/silence-unless-failed /tools/backup-mysql

### permit and deny - Easily set fine-grained permissions using ACLs

`permit` gives a user access to a single file, or recursive access to a directory, using ACLs. In case of directories, the default ACL is modified too so that any new files created in that directory inherit the ACL rule that allows access for the given user.

`deny` removes all ACLs for a given user on a single file, or recursively on a directory.

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

### silcence-unless-failed

Runs the given command but only print its output (both STDOUT and STDERR) if its exit code is non-zero. The script's own exit code is the same as the command's exit code.

    /tools/silence-unless-failed my-command arg1 arg2 --arg3
