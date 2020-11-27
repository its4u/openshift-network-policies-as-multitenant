#!/bin/bash

if which jq > /dev/null 2> /dev/null;then
    echo "jq found.";
else
    echo "Please install jq";
    exit 1
fi


if which oc > /dev/null 2> /dev/null;then
    echo "oc found.";
else
    echo "Please install oc";
    exit 1
fi

exit 0

if oc whoami > /dev/null 2> /dev/null;then
    echo "Already connected to cluster."
else
    echo "Please login to cluster using oc login"
    exit 1
fi


echo "Retrieving default project template..."
oc adm create-bootstrap-project-template -o json > default_template.json

echo "Adding Network Policy to template..."
jq '.objects += [$var1,$var2,$var3]' default_template.json \
    --slurpfile var1 ./network-policies/allow-same-namespace.json \
    --slurpfile var2 ./network-policies/allow-from-openshift-ingress.json \
    --slurpfile var3 ./network-policies/allow-from-openshift-monitoring.json \
    > new_default_template.json;

echo "Uploading template to cluster..."
oc create -f new_default_template.json -n openshift-config

echo "Update cluster to use this template by default..."
oc patch project.config.openshift.io/cluster --type=json \
    -p='[{"op":"replace", "path":"/spec/projectRequestTemplate/name", "value":"project-request"}]'

echo "Cleaning files..."
rm ./default_template.json
rm ./new_default_template.json

echo ""
echo "Done! create new project to verify changes have been made"
echo "> oc new-project test-network-policy"
echo "> oc get networkpolicy"
echo "Should give 3 policies, 'allow-from-openshift-ingress', 'allow-from-openshift-monitoring', 'allow-same-namespace'"


