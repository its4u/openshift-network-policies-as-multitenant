#!/bin/bash

source vars

#####
## Verify everything required is available
#####
    #jq to edit json formated stream
    if ! which jq > /dev/null 2> /dev/null;then
        echo "Please install jq";
        exit 1
    fi

    #oc to manipulate OpenShift cluster
    if ! which oc > /dev/null 2> /dev/null; then
        echo "Please install oc."
        exit 1
    fi

    #connection to cluster
    if ! oc whoami > /dev/null 2> /dev/null; then
        echo "Not connected to cluster. Please run 'oc login' with administrator credentials."
        exit 1
    fi

echo "Exclude selected projects from this patch"

#If no namespaces is given in parameters, use current namespaces
function use_current_namespace_by_default {
    if [ $# -eq 0 ] ; then
        if oc project > /dev/null 2> /dev/null; then
            echo $(oc project -q);
        else
            echo "Please specify one or more namespaces names, or select a valid namespace with oc project command.";
            exit 1;
        fi;
    else
        echo $@
    fi;
}
set $(use_current_project_by_default $@)

#for each parameters given, do
for ns in $@; do
    echo ">>Analysing namespace $p";

    #Get the namespace state
    res=$(oc get namespace $ns -o jsonpath='{.metadata.labels.'$NS_LABEL'}')

    #Do not treate already excluded projects
    if [ ! "$res" = "true" ]; then
        echo "Not concerned...";
        continue;
    fi;

    #For each policies in the namespace (see "done" for the list)
    while read -r np; do

        #Check if policy has been created by this script
        res=$(oc get networkpolicy $np -n $ns -o jsonpath='{.metadata.labels.'$NP_LABEL'}');
        
        #Remove the policy only if applied by this script
        if [ "$res" = "true" ]; then
            oc delete networkpolicy $np -n $ns;
        fi;

    #get all network policies of the namespace, and format the output to get only names.
    done < <(oc get networkpolicy -o name -n $ns | sed 's:^networkpolicy.networking.k8s.io/::')

    #Change the project state
    oc label namespace $ns $NS_LABEL="false" --overwrite;
done