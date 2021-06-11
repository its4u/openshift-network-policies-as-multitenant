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


#####
## Removing NetworkPolicies to existing namespaces
#####
while read -r ns; do
    echo ">>Analysing namespace $ns";

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
    oc label namespace $ns $NS_LABEL-;
    
    echo "";

#get all projects name, exclude 'default' and all project begenning with 'openshift' and 'kube'
done < <(oc get namespace -o name | sed 's:^namespace/::' | grep -vE '^(default$|openshift|kube)')



#####
## Removing from default template
#####
if oc get template -n openshift-config | grep "project-request" > /dev/null; then
    oc get template project-request -n openshift-config -o json > $TEMPLATE;
    #Remove network policies in the template.
    jq 'del(.objects[] | select(.kind == "NetworkPolicy") | select(.metadata.labels["'$NP_LABEL'"]=="true"))' $TEMPLATE > $TEMP_FILE && mv $TEMP_FILE $TEMPLATE
    #Remove annotation on the template
    jq 'del( .objects[] | select(.kind == "Project") | .metadata.labels."'$NS_LABEL'" )' $TEMPLATE > $TEMP_FILE && mv $TEMP_FILE $TEMPLATE

    oc apply -f $TEMPLATE -n openshift-config
fi;


echo "Update cluster to use this template by default..."
oc patch project.config.openshift.io/cluster --type=json -p='[{"op": "remove", "path": "/spec/projectRequestTemplate"}]'


echo "Cleaning files..."
rm $TEMPLATE $TEMP_FILE $TEMP_FIL2