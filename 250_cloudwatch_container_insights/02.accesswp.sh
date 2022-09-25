#!/bin/bash

export SERVICE_URL=$(kubectl get svc -n wordpress-cwi understood-zebu-wordpress --template "{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}")
echo "Public URL: http://$SERVICE_URL/"

echo -n "Wailt.....Press any key when Dobal says 'please press any key'"
read text

export ADMIN_URL="http://$SERVICE_URL/admin"
export ADMIN_PASSWORD=$(kubectl get secret --namespace wordpress-cwi understood-zebu-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)

echo "Admin URL: http://$SERVICE_URL/admin
Username: user
Password: $ADMIN_PASSWORD
"
