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





echo "Removing NetworkPolicy on projects..."
while read -r p; do
    echo ">>Analysing project $p";

    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    if [ "$res" = "\"applied\"" ]; then
        while read -r np; do

            res=$(oc get networkpolicy $np -n $p -o json | jq .metadata.annotations[""]);
            
            if [ "$res" = "\"true\"" ]; then
                oc delete networkpolicy $np -n $p;
            fi;

        done < <(oc get networkpolicy -o name -n $p | sed 's:^networkpolicy.networking.k8s.io/::')

        oc annotate namespace $p $ANNOTATION=notapplied --overwrite;
    else
        echo "Not concerned..."
    fi
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')