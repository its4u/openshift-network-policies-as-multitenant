ANNOTATION="openshift-network-policies-as-multitenant"

#Verify everything required is available
function verify_installation {
    #jq to edit json formated stream
    if which jq > /dev/null 2> /dev/null;then
        echo "jq found.";
    else
        echo "Please install jq";
        exit 1
    fi

    #oc to manipulate OpenShift cluster
    if which oc > /dev/null 2> /dev/null; then
        echo "oc found."
    else
        echo "Please install oc."
        exit 1
    fi
    
    #connection to cluster
    if oc whoami > /dev/null 2> /dev/null; then
        echo "Connected to cluster."
    else
        echo "Not connected to cluster. Please run 'oc login' with administrator credentials."
        exit 1
    fi
}

#Verify the json provided
function verify_json {
    f=$1

    #Apply a certain annotation, to keep track of what has been created
    res=$(jq '.metadata.annotations["'$ANNOTATION'"]' $f)
    if [ ! "$res" = "\"true\"" ]; then
        jq '.metadata.annotations |= . + { "'$ANNOTATION'" : "true" }' $f > tmp.json;
        mv tmp.json $f;
    fi;
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