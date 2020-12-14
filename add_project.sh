#!/bin/bash

source functions.sh
verify_installation


echo "Applying Network Policies on selected projects"

#If no project is given in parameters, use current project
set $(use_current_project_by_default $@)

#for each parameters given, do
for p in $@; do
    echo ">>Analysing project $p";

    #Do nothing if project is a default openshift project
    if [ "$(echo $p | grep -vE '^(default$|openshift|kube)')" = "" ]; then
        echo "Carefull, cannot apply Network Policy on default OpenShift projects."
        echo "Skipping...";
        continue;
    fi;

    #Get the project state
    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    #Warning about excluded projects
    if [ "$res" = "\"NotConcerned\"" ]; then
        echo "Project was excluded from this patch. Reverting exclusion..."
    fi;

    #Apply each policies in folder
    for f in ./network-policies/*.json; do
        verify_json $f

        oc create -n $p -f $f;
    done;

    #change the project state
    oc annotate namespace $p $ANNOTATION=Applied --overwrite;
done
