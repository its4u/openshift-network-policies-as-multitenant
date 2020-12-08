#!/bin/bash

ANNOTATION="openshift-network-policies-as-multitenant"

if which jq > /dev/null 2> /dev/null;then
    echo "jq found.";
else
    echo "Please install jq";
    exit 1
fi

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

    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    if [ "$res" = "\"applied\"" ]; then
        echo "Already applied.";
    elif [ "$res" = "\"NotConcerned\"" ]; then
        echo "Not Concerned";
    else
        oc annotate namespace $p $ANNOTATION=applied --overwrite;
        
        for f in ./network-policies/*.json; do

            res=$(jq '.metadata.annotations["'$ANNOTATION'"]' $f)
            if [ ! "$res" = "\"true\"" ]; then
                jq '.metadata.annotations |= . + { "'$ANNOTATION'" : "true" }' $f > tmp.json;
                mv tmp.json $f;
            fi;

            oc create -n $p -f $f;
        done;
    fi;
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')


