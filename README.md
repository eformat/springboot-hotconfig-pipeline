# Springboot Hot Reconfiguration using ConfigMaps and Pipelines

Demonstrate pipeline promotion of both images and configuration

Make use of SpringBoot hot redeploy (without jvm restart) of application properties
combined with Openshift ConfigMaps to store the environment specific application properties

Uses fabric8 maven for s2i development

## Source code generation
The source code was generated using
```
http://start.spring.io/
-- add web, actuator
-- download the demo.zip
```

git clone the code, unzip demo.zip and run the script over it to patch source code:

```
chmod 755 do-demo-spring-boot.sh
./do-demo-spring-boot.sh
```

## Create Openshift projects
```
oc new-project cicd --display-name='CICD Jenkins' --description='CICD Jenkins'
oc new-project development --display-name='MyApp Development' --description='MyApp Development'
oc new-project testing --display-name='MyApp Testing' --description='MyApp Testing'
oc new-project production --display-name='MyApp Production' --description='MyApp Production'
```

## Add role based access for spring cloud kubernetes to view configmap
```
oc policy add-role-to-user view --serviceaccount=default -n development
oc policy add-role-to-user view --serviceaccount=default -n testing
oc policy add-role-to-user view --serviceaccount=default -n production
```

## Add role based access for jenkins service account
```
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n development
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n testing
oc policy add-role-to-user edit system:serviceaccount:cicd:jenkins -n production
```

## Add image pull permission for image tag and promotion
```
oc policy add-role-to-group system:image-puller system:serviceaccounts:testing -n development
oc policy add-role-to-group system:image-puller system:serviceaccounts:production -n development
```

## Create Jenkins CICD based on official RHEL supported image
```
oc project cicd
oc new-app --template=jenkins-ephemeral -p JENKINS_IMAGE_STREAM_TAG=jenkins-1-rhel7:latest,NAMESPACE=openshift,MEMORY_LIMIT=2048Mi,JENKINS_PASSWORD=password
```

## Create our pipeline
```
oc create -n cicd -f https://raw.githubusercontent.com/eformat/springboot-hotconfig-pipeline/master/pipeline.yaml
```

## Create our Development application
```
oc project development
git clone git@github.com:eformat/springboot-hotconfig-pipeline.git
cd ~/springboot-hotconfig-pipeline
mvn clean install fabric8:run
oc expose service demo --hostname=demo-development.192.168.137.3.xip.io --name=demo
```

## Test our running application with default configuration
```
$ curl http://demo-development.192.168.137.3.xip.io/api/hello/mike
{"response":"default hello","count":1,"your-name":"mike"}
```

## Create our configmap
```
oc create -f configmap.yml
```

## Test our running application using configmap
```
$ curl http://demo-development.192.168.137.3.xip.io/api/hello/mike
{"response":"hello, spring cloud kubernetes !","count":2,"your-name":"mike"}
```

## Change our development build configuration to work as Git based S2I for our pipeline build
```
oc import-image --insecure=true -n openshift docker.io/fabric8/s2i-java:1.3 --confirm
oc delete bc demo-s2i
oc create -f source-buildconfig.json
```

## Create our Testing application based on image tag
```
oc project testing
oc create dc demo --image=172.30.18.201:5000/development/demo:promoteQA
oc deploy demo --cancel
oc patch dc/demo -p '{"spec":{"template":{"spec":{"containers":[{"name":"default-container","imagePullPolicy":"Always"}]}}}}'
oc expose dc demo --port=8080
oc expose service demo --hostname=demo-testing.192.168.137.3.xip.io --name=demo
```

## Create our Produciton application based on image tag
```
oc project production
oc create dc demo --image=172.30.18.201:5000/development/demo:promotePRD
oc deploy demo --cancel
oc patch dc/demo -p '{"spec":{"template":{"spec":{"containers":[{"name":"default-container","imagePullPolicy":"Always"}]}}}}'
oc expose dc demo --port=8080
oc expose service demo --hostname=demo-production.192.168.137.3.xip.io --name=demo
```

## Perform Our Pipeline Build
```
oc project cicd
oc start-build pipeline
```

## Hot Config
Edit config maps to change message on the fly, hot reloaded into springboot application

```
oc edit configmap/helloservice
```