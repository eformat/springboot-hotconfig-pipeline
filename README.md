# Springboot Hot Reconfiguration using ConfigMaps and Pipelines

Demonstrate pipeline promotion of both images and configuration

Make use of SpringBoot hot redeploy (without jvm restart) of application properties
combined with Openshift ConfigMaps to store the envireonment specific application properties

## Create Openshift projects
oc new-project cicd --display-name='CICD Jenkins' --description='CICD Jenkins'
oc new-project development --display-name='MyApp Development' --description='MyApp Development'
oc new-project testing --display-name='MyApp Testing' --description='MyApp Testing'
oc new-project production --display-name='MyApp Production' --description='MyApp Production'

## Add role based access for spring cloud kubernetes to view configmap
oc policy add-role-to-user view --serviceaccount=default -n development
oc policy add-role-to-user view --serviceaccount=default -n testing
oc policy add-role-to-user view --serviceaccount=default -n production

## Add role based access for jenkins service account
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n development
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n testing
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n production

## Add image pull permission for image tag and promotion
oc policy add-role-to-group system:image-puller system:serviceaccounts:testing -n development
oc policy add-role-to-group system:image-puller system:serviceaccounts:production -n development

## Create Jenkins CICD based on official RHEL supported image
oc project cicd
oc new-app --template=jenkins-ephemeral -p JENKINS_IMAGE_STREAM_TAG=jenkins-1-rhel7:latest,NAMESPACE=openshift,MEMORY_LIMIT=2048Mi,JENKINS_PASSWORD=password

