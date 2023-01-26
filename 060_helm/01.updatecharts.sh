#!/bin/bash

# first, add the default repository, then update
helm repo add stable https://charts.helm.sh/stable
helm repo update
