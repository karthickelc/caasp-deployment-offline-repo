#!/bin/bash
# "skuba cluster images" to get the latest bootstrap images
MIRROR="registry.example.com:5000" #(This should match the FQDN of your offline registry)
REMOTE="registry.suse.com/caasp/v4"
IMAGES="
hyperkube:v1.16.2
hyperkube:v1.15.2
etcd:3.3.15
etcd:3.3.11
coredns:1.6.2
coredns:1.3.1
pause:3.1
skuba-tooling:0.1.0
cilium-init:1.5.3
cilium-operator:1.5.3
cilium:1.5.3
caasp-dex:2.16.0
gangway:3.1.0-rev4
kured:1.2.0-rev4
"
for IMAGE in ${IMAGES}; do
        echo $IMAGE
        docker pull $REMOTE/$IMAGE
        docker tag $REMOTE/$IMAGE $MIRROR/$REMOTE/$IMAGE
        docker push $MIRROR/$REMOTE/$IMAGE
done

