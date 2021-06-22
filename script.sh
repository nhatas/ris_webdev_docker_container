#!/bin/bash
set -e
err_report() {
  echo "Error on line $1, error code:$?"
}
trap 'err_report $LINENO' ERR

# start apache2
service apache2 start

DIR=$MYSQL_PATH
# script that creates dir and autopopulates db (everything necessary for db )
# environment variable for directory 
# MY_SQL_DIR=/storage... 
#UUID=`uuidgen`

#cd $DIR
#mysql_dir=$DIR/$UUID

mysql_dir=$DIR

if [ ! -d "$mysql_dir" ]
then
    echo "MYSQL directories don't exist"
    mkdir -p $mysql_dir
    mkdir -p $mysql_dir/run $mysql_dir/run/mysqld
    mkdir -p $mysql_dir/lib $mysql_dir/lib/mysql
    mkdir -p $mysql_dir/log $mysql_dir/log/mysql
    chmod 755 $mysql_dir/lib/mysql
    echo "MYSQL directories created"
else
    echo "MYSQL directories exist"
fi



#make cnf file
#337     print OUT <<EOT;
cat <<EOF > $mysql_dir/my.cnf
[client]
port            = 3306
socket          = /tmp/mysqld.sock

[mysqld_safe]
socket          = /tmp/mysqld.sock
nice            = 0

[mysqld]
user            = mysql
pid-file        = $mysql_dir/run/mysqld/mysqld.pid
socket          = /tmp/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = $mysql_dir/lib/mysql
tmpdir          = /tmp
skip-external-locking
bind-address            = 127.0.0.1
key_buffer              = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
myisam-recover         = BACKUP
query_cache_limit       = 1M
query_cache_size        = 16M
log_error = $mysql_dir/log/mysql/error.log
expire_logs_days        = 10
max_binlog_size         = 100M
innodb_use_native_aio = 0

[mysqldump]
quick
quote-names
max_allowed_packet      = 16M

[mysql]

[isamchk]
key_buffer              = 16M

!includedir /etc/mysql/conf.d/
EOF

mysql_install_db --user=$USER --basedir=/usr/ --ldata=$mysql_dir/lib/mysql/
mysqld_safe --defaults-file=$mysql_dir/my.cnf --general-log &