#!/bin/bash

kubectl -n mysql delete pod mysql-1

kubectl -n mysql get pod mysql-1 -w
