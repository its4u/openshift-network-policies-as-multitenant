#!/bin/bash
ANNOTATION="openshift-network-policies-as-multitenant"
TEMP_FILE="/tmp/openshift-network-policies-as-multitenant_tmp-file.json"

#Verify everything required is available
function verify_installation {
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
}

function use_current_project_by_default {
    if [ $# -eq 0 ] ; then
        if oc project > /dev/null 2> /dev/null; then
            echo $(oc project -q);
        else
            echo "Please specify one or more project names, or select a valid project with oc command.";
            exit 1;
        fi;
    else
        echo $@
    fi;
}

function print_list {
    echo "param1 param2 param3 ouech"
}
verify_installation

echo "Removing NetworkPolicy on projects..."

#For each project (see "done" for the list), remove currently applied network policies
while read -r p; do
    echo ">>Analysing project $p";

    #Check the project state
    res=$(oc get project $p -o jsonpath='{.metadata.annotations.'$ANNOTATION'}')

    #Remove policies only if project has applied policies by this script
    if [ "${res,,}" = "applied" ]; then

        #For each policies in the project (see "done" for the list)
        while read -r np; do

            #Check if policy has been created by this script
            res=$(oc get networkpolicy $np -n $p -o jsonpath='{.metadata.annotations.'$ANNOTATION'}');
            
            #Remove the policy only if applied by this script
            if [ "${res,,}" = "true" ]; then
                oc delete networkpolicy $np -n $p;
            fi;

        #get all network policies of the project, and format the output to get only names.
        done < <(oc get networkpolicy -o name -n $p | sed 's:^networkpolicy.networking.k8s.io/::')

        #Change the project state
        oc annotate namespace $p $ANNOTATION- --overwrite;
    
    #If project state is not "applied", nothing to do
    else
        echo "Not concerned..."
    fi

    echo "";

#get all projects name, exclude 'default' and all project begenning with 'openshift' and 'kube'
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')

#Get the original template file
oc get template project-request -n openshift-config -o json > template.json;
#Remove network policies in the template.
jq 'del(.objects[] | select(.kind == "NetworkPolicy") | select(.metadata.annotations["'$ANNOTATION'"]=="true"))' template.json > $TEMP_FILE && mv $TEMP_FILE template.json
#Remove annotation on the template
jq 'del( .objects[] | select(.kind == "Project") | .metadata.annotations."'$ANNOTATION'" )' template.json > $TEMP_FILE && mv $TEMP_FILE template.json

oc apply -f template.json -n openshift-config
rm template.json
