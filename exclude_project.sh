#!/bin/bash

source functions.sh
verify_installation


echo "Exclude selected projects from this patch"

#If no project is given in parameters, use current project
set $(use_current_project_by_default $@)

#for each parameters given, do
for p in $@; do
    echo ">>Analysing project $p";

    #Do nothing if project is a default openshift project
    if [ "$(echo $p | grep -vE '^(default$|openshift|kube)')" = "" ]; then
        echo "Default OpenShift projects are already excluded."
        echo "Skipping...";
        continue;
    fi;

    #Get the project state
    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    #Do not treate already excluded projects
    if [ "$res" = "\"NotConcerned\"" ]; then
        echo "Not concerned..."
    else
        while read -r np; do

            res=$(oc get networkpolicy $np -n $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]');
            
            if [ "$res" = "\"true\"" ]; then
                oc delete networkpolicy $np -n $p;
            fi;

        done < <(oc get networkpolicy -o name -n $p | sed 's:^networkpolicy.networking.k8s.io/::')

        #Change the project state
        oc annotate namespace $p $ANNOTATION=NotConcerned --overwrite;
    fi
done
