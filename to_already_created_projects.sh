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
    
    ingress=true;
    monitoring=true;
    namespace=true;

    while read -r np; do
        case $np in
            "allow-from-openshift-ingress") ingress=false;;
            "allow-from-openshift-monitoring") monitoring=false;;
            "allow-same-namespace") namespace=false;;
            *) echo "unknown policy";;
        esac
    done < <(oc get networkpolicy -o name -n $p| sed 's:^networkpolicy.networking.k8s.io/::');

    if [ "$ingress" = true ];then
        oc create -n $p -f ./network-policies/allow-from-openshift-ingress.json;
    fi
    if [ "$monitoring" = true ];then
        oc create -n $p -f ./network-policies/allow-from-openshift-monitoring.json;
    fi
    if [ "$namespace" = true ];then
        oc create -n $p -f ./network-policies/allow-same-namespace.json;
    fi
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')


