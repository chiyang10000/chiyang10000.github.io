---
layout:     post
title:      Setup DBMS on macOS
date:       2018-08-28
author:     Chiyang Wan
summary:    
categories: DBMS
thumbnail:  heart
tags:
 - DBMS
---

This post introduces a quick reference on how to set up serveral main stream DBMS on macOS(tested on macOS 10.12 10.13 10.14). The code snippets are expected to run in `bash` directly(though some confusing syntax highlightings occur inside this page), as a result of which  there is no need to swith between shell interpreter and text editor.

Each code snippet is divided into to 6 parts, i.e. `Install, Configure, Initialize, Start, Connect and Stop`.

And all the related data is stored inside `/db_data/`.

## System Prerequisite

- [x] Setup passphraseless ssh

    ```bash
    ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    chmod 0600 ~/.ssh/authorized_keys
    ```

    Now you can `ssh localhost` without a passphrase. If you meet `Port 22 connecting refused` error, turn on `Remote login` in your Mac's `System Preferences->Sharing`.

- [x] Configure sysctl.conf

    ```bash
    sudo tee /etc/sysctl.conf << EOF
    kern.sysv.shmmax=2147483648
    kern.sysv.shmmin=1
    kern.sysv.shmmni=64
    kern.sysv.shmseg=16
    kern.sysv.shmall=524288
    kern.maxfiles=65535
    kern.maxfilesperproc=65536
    kern.corefile=/cores/core.%N.%P
    EOF
    
    sudo sysctl -a
    ```

- [x] Add /db_data/ folder

    ```bash
    sudo install -o $USER -d /db_data/
    ```

## HDFS

```bash
# Install
brew install hadoop

# Configure
export HADOOP_HOME=/usr/local/opt/hadoop/libexec
tee $HADOOP_HOME/etc/hadoop/core-site.xml << EOF
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://localhost:8020</value>
    </property>
    <property>
         <name>hadoop.proxyuser.admin.hosts</name>
         <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.admin.groups</name>
        <value>*</value>
    </property>
</configuration>
EOF
tee $HADOOP_HOME/etc/hadoop/hdfs-site.xml << EOF
<configuration>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///db_data/hdfs/name</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///db_data/hdfs/data</value>
    </property>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
EOF

# Initialize
hdfs namenode -format

# Start
start-dfs.sh

# Connect
hdfs dfsadmin -report
hdfs dfs -ls /

# Stop
stop-dfs.sh
```

## OushuDB

```bash
# Install
brew tap chiyang10000/homebrew-yizhiyang
brew search chiyang10000
brew reinstall oushudb

# Configure
tee /usr/local/opt/oushudb/etc/hawq-site.xml << EOF
<configuration>
    <property>
        <name>hawq_dfs_url</name>
        <value>localhost:8020/hawq_default</value>
        <description>URL for accessing HDFS.</description>
    </property>
    <property>
        <name>hawq_master_address_host</name>
        <value>localhost</value>
    </property>
    <property>
        <name>hawq_master_address_port</name>
        <value>5432</value>
    </property>
    <property>
        <name>hawq_segment_address_port</name>
        <value>40000</value>
    </property>
    <property>
        <name>hawq_master_directory</name>
        <value>/db_data/hawq-data-directory/masterdd</value>
    </property>
    <property>
        <name>hawq_segment_directory</name>
        <value>/db_data/hawq-data-directory/segmentdd</value>
    </property>
    <property>
        <name>hawq_master_temp_directory</name>
        <value>/tmp</value>
    </property>
    <property>
        <name>hawq_segment_temp_directory</name>
        <value>/tmp</value>
    </property>
    <property>
        <name>hawq_magma_port_master</name>
        <value>50000</value>
    </property>
    <property>
        <name>hawq_magma_port_segment</name>
        <value>50005</value>
    </property>
    <property>
        <name>hawq_magma_locations_master</name>
        <value>file:///db_data/hawq-data-directory/magma_master</value>
    </property>
    <property>
        <name>hawq_magma_locations_segment</name>
        <value>file:///db_data/hawq-data-directory/magma_segment</value>
    </property>
</configuration>
EOF

# Initialize
source /usr/local/opt/oushudb/greenplum_path.sh
hawq init cluster -a

# Start
source /usr/local/opt/oushudb/greenplum_path.sh
hawq start cluster -a

# Connect
source /usr/local/opt/oushudb/greenplum_path.sh
psql -d postgres

# Stop
source /usr/local/opt/oushudb/greenplum_path.sh
hawq stop cluster -a
```

## Hive

```bash
# Install
brew install hive

# Configure
export HIVE_HOME=/usr/local/opt/hive/libexec
tee $HIVE_HOME/conf/hive-site.xml << EOF
<configuration>
  <property>
    <name>javax.jdo.option.ConnectionURL</name>
    <value>jdbc:derby:;databaseName=/db_data/hive_metastore_db;create=true</value>
  </property>
  <property>
    <name>hive.server2.thrift.port</name>
    <value>10000</value>
  </property>
</configuration>
EOF

# Initialize
hadoop fs -mkdir       /tmp
hadoop fs -mkdir -p    /user/hive/warehouse
hadoop fs -chmod g+w   /tmp
hadoop fs -chmod g+w   /user/hive/warehouse
schematool -dbType derby -initSchema

# Start
hive --service hiveserver2
hive --service metastore

# Connect
beeline -n $USER -u jdbc:hive2://127.0.0.1:10000

# Stop
killall hive
```

## PostgreSQL

```bash
# Install
brew install postgresql

# Configure/Initialize
pg_ctl -D /db_data/postgresql/ init

# Start
pg_ctl -D /db_data/postgresql/ start

# Connect
psql

# Stop
pg_ctl -D /db_data/postgresql/ stop
```

## MySQL

```bash
# Install
brew install mysql

# Configure/Initialize
mysqld --initialize-insecure --datadir=/db_data/mysql/

# Start
mysqld --datadir=/db_data/mysql/

# Connect
mysql -u root -D mysql

# Stop
killall mysqld
```
