#!/bin/bash

if which oc > /dev/null 2> /dev/null; then
    echo "oc found."
else
    echo "Please install oc."
    exit 1
fi

if oc whoami > /dev/null 2> /dev/null; then
    echo "Connected to cluster."
else
    echo "Not connected to cluster. Please run 'oc login' with administrator credentials."
    exit 1
fi





echo "Applying NetworkPolicy on projects..."

while read -r p; do
    echo ">>Analysing project $p";

    res=$(oc get project $p -o json | jq '.metadata.annotations["openshift-network-policies-as-multitenant"]')

    if [ "$res" = "\"applied\"" ]; then
        echo "Already applied.";
    else
        oc annotate namespace $p openshift-network-policies-as-multitenant=applied --overwrite;
        
        for f in ./network-policies/*.json; do
            oc create -n $p -f $f;
        done;
    fi;
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')


