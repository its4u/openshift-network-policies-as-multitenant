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

if oc whoami > /dev/null 2> /dev/null;then
    echo "Already connected to cluster."
else
    echo "Please login to cluster using oc login"
    exit 1
fi





echo "Retrieving default project template..."
oc adm create-bootstrap-project-template -o json > template.json

echo "Adding Network Policy to template..."
for f in ./network-policies/*.json; do
    jq '.objects += $var1' \
        template.json \
        --slurpfile var1 $f \
        > new_template.json;
    mv new_template.json template.json;
done;

jq '.objects[0].metadata.annotations |= . + { "openshift-network-policies-as-multitenant" : "applied" }' \
    template.json \
    > new_template.json;
mv new_template.json template.json;

echo "Uploading template to cluster..."
oc apply -f template.json -n openshift-config

echo "Update cluster to use this template by default..."
oc patch project.config.openshift.io/cluster --type=json \
    -p='[{"op":"replace", "path":"/spec/projectRequestTemplate/name", "value":"project-request"}]'

echo "Cleaning files..."
rm template.json