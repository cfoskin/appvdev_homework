#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
PROD_PROJECT=$GUID-parks-prod
DEV_PROJECT=$GUID-parks-dev

echo "Setting up Parks Production Environment in project ${PROD_PROJECT}"

# Code to set up the parks development project.

# To be Implemented by Student
oc new-project $PROD_PROJECT --display-name="${GUID} AdvDev Homework Parks Production"

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user admin system:serviceaccount:$GUID-jenkins:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-group system:image-puller system:serviceaccounts:${PROD_PROJECT} -n ${DEV_PROJECT}

echo "Creating internal mongo service.."
oc create -f ../templates/mongodb-service-internal-template.yml 

echo "Creating mongo service.."
oc create -f ../templates/mongodb-service-template.yml 

echo "Creating mongo StatefulSet.."
oc create -f ../templates/mongodb-statefulset-template.yml 


echo "Checking if Mongodb Stateful set is Ready..."
check_if_ready () {
   while : ; do
   	 echo "Checking mongodb-$1 pod.."
   	 output=$(oc get pods --field-selector=status.phase='Running' | grep 'mongodb-'$1 | grep '1/1' | awk '{print $2}')
   	 echo $output
	 [[ "${output}" != "1/1" ]] || break #testing here
	 echo "...no Sleeping 10 seconds."
	 sleep 10
   done	 
} 

check_if_ready "0"
check_if_ready "1"
check_if_ready "2"

echo "Mongodb Deployment complete"
# # Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# # The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

echo "Creating Blue Deployment Configs.."
oc new-app $DEV_PROJECT/mlbparks:0.0 --name=mlbparks-blue --allow-missing-imagestream-tags=true -n $PROD_PROJECT
oc new-app $DEV_PROJECT/nationalparks:0.0 --name=nationalparks-blue --allow-missing-imagestream-tags=true -n $PROD_PROJECT
oc new-app $DEV_PROJECT/parksmap:0.0 --name=parksmap-blue --allow-missing-imagestream-tags=true -n $PROD_PROJECT

echo "Setting Blue triggers.."
oc set triggers dc/mlbparks-blue --remove-all -n $PROD_PROJECT
oc set triggers dc/nationalparks-blue --remove-all -n $PROD_PROJECT
oc set triggers dc/parksmap-blue --remove-all -n $PROD_PROJECT

echo "Creating Green Deployment Configs.."
oc new-app $DEV_PROJECT/mlbparks:0.0 --name=mlbparks-green --allow-missing-imagestream-tags=true -n $PROD_PROJECT
oc new-app $DEV_PROJECT/nationalparks:0.0 --name=nationalparks-green --allow-missing-imagestream-tags=true -n $PROD_PROJECT
oc new-app $DEV_PROJECT/parksmap:0.0 --name=parksmap-green --allow-missing-imagestream-tags=true -n $PROD_PROJECT

echo "Setting Green triggers.."
oc set triggers dc/mlbparks-green --remove-all -n $PROD_PROJECT
oc set triggers dc/nationalparks-green --remove-all -n $PROD_PROJECT
oc set triggers dc/parksmap-green --remove-all -n $PROD_PROJECT

echo "Create Configmaps.."
oc create configmap mlbparks-config --from-literal="DB_HOST=mongodb " --from-literal="DB_PORT=27017" \
 --from-literal="DB_USERNAME=mongodb" --from-literal="DB_PASSWORD=mongodb" \
 --from-literal="DB_NAME=parks" --from-literal="DB_REPLICASET=rs0" \
 --from-literal="APPNAME=MLB Parks (Blue)" -n $PROD_PROJECT

oc create configmap nationalparks-config --from-literal="DB_HOST=mongodb " --from-literal="DB_PORT=27017" \
 --from-literal="DB_USERNAME=mongodb" --from-literal="DB_PASSWORD=mongodb" \
 --from-literal="DB_NAME=parks" --from-literal="DB_REPLICASET=rs0" \
 --from-literal="APPNAME=National Parks (Blue)" -n $PROD_PROJECT

oc create configmap parksmap-config --from-literal="DB_HOST=mongodb " --from-literal="DB_PORT=27017" \
 --from-literal="DB_USERNAME=mongodb" --from-literal="DB_PASSWORD=mongodb" \
 --from-literal="DB_NAME=parks" --from-literal="DB_REPLICASET=rs0" \
 --from-literal="APPNAME=ParksMap (Blue)" -n $PROD_PROJECT

echo "Update the DeploymentConfig to use the configmaps.. "
oc set env dc/mlbparks-blue --from=configmap/mlbparks-config 
oc set env dc/nationalparks-blue --from=configmap/nationalparks-config
oc set env dc/parksmap-blue --from=configmap/parksmap-config

echo "Update the DeploymentConfig to use the configmaps.. "
oc set env dc/mlbparks-green --from=configmap/mlbparks-config 
oc set env dc/nationalparks-green --from=configmap/nationalparks-config
oc set env dc/parksmap-green --from=configmap/parksmap-config

echo "Finished!"