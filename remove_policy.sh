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


echo "Removing NetworkPolicy on projects..."
while read -r p; do
    echo ">>Analysing project $p";

    res=$(oc get project test-lucas2 -o json | jq '.metadata.annotations["openshift-network-policies-as-multitenant"]')

    if [ "$res" = "\"applied\"" ]; then
        while read -r np; do
            oc delete networkpolicy $np
        done < <(oc get networkpolicy -o name -n $p | sed 's:^networkpolicy.networking.k8s.io/::')

        oc annotate namespace $p openshift-network-policies-as-multitenant=notapplied --overwrite;
    fi;
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')