#!/bin/bash

ANNOTATION="openshift-network-policies-as-multitenant"

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
pr_exist="false";
while read -r tp; do
    if [ "$tp" = "project-request" ]; then
        pr_exist="true";
        break;
    fi;
done < <(oc get template -n openshift-config -o name | sed "s:template.template.openshift.io/::")

if [ "$pr_exist" = "true" ]; then
    oc get template project-request -n openshift-config -o json > template.json;
    jq 'del(.objects[] | select(.metadata.annotations["'$ANNOTATION'"]=="true"))' template.json > tmp.json
    mv tmp.json template.json
else
    oc adm create-bootstrap-project-template -o json > template.json;
    oc create -f template.json -n openshift-config --save-config
fi;

echo "Adding Network Policy to template..."
for f in ./network-policies/*.json; do

    res=$(jq '.metadata.annotations["'$ANNOTATION'"]' $f)
    if [ ! "$res" = "\"true\"" ]; then
        jq '.metadata.annotations |= . + { "'$ANNOTATION'" : "true" }' $f > tmp.json;
        mv tmp.json $f;
    fi;

    jq '.objects += $var1' \
        template.json \
        --slurpfile var1 $f \
        > new_template.json;
    mv new_template.json template.json;
done;

jq '.objects[0].metadata.annotations |= . + { "'$ANNOTATION'" : "applied" }' \
    template.json \
    > new_template.json;
mv new_template.json template.json;

echo "Uploading template to cluster..."
oc apply -f template.json -n openshift-config

echo "Update cluster to use this template by default..."
res=$(oc get project.config.openshift.io/cluster -o json | jq '.spec.projectRequestTemplate.name')
if [ "$res" = "null" ]; then
    oc get project.config.openshift.io/cluster -o json | \
        jq '.spec.projectRequestTemplate |= . + {"name":"project-request"}' > tmp.json
    oc apply -f tmp.json -n openshift-config
    rm tmp.json
elif [ ! "$res" = "\"project-request\"" ]; then
    oc patch project.config.openshift.io/cluster --type=json \
        -p='[{"op":"replace", "path":"/spec/projectRequestTemplate/name", "value":"project-request"}]'
fi;

echo "Cleaning files..."
rm template.json