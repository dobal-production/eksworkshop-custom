#!/bin/bash

# create db, teble and insert data on mysql writer
kubectl -n mysql run mysql-client --image=mysql:5.7 -i --rm --restart=Never --\
  mysql -h mysql-0.mysql <<EOF
CREATE DATABASE test;
CREATE TABLE test.messages (message VARCHAR(250));
INSERT INTO test.messages VALUES ('hello, from mysql-client');
EOF

# select from mysql reader
kubectl -n mysql run mysql-client --image=mysql:5.7 -it --rm --restart=Never --\
  mysql -h mysql-read -e "SELECT * FROM test.messages"
