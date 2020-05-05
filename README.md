# caasp-deployment-offline-repo
In this hands on lab exercise, we will look at how to setup your offline environment for application delivery using Offline repo method. 

Lab 1 : Setup RMT server and Mirror repositories 
Lab 2 : Create offline Docker registry
Lab 3 : Setup reverse proxy and virtual hosts
Lab 4 : Mirror CaasP and CAP images locally
Lab 5 : Client side changes to access local registry

For this lab you will have to create following Vms ,

    1. DNS sever
    2. RMT server
    3. Management server
    4. Master node
    5. Worker01

Lab 1: Setup RMT server and Mirror repositories
 
1. On your lab environment, open the Virtual Machine manager and connect to rmt virtual machine console .  When the server has booted and presents a login screen, close the console window 

2. When the login screen is displayed, use the following credentials:
User: tux
Password: linux

3. RMT server is pre-installed in RMT VM with base SLES 15Sp1 . We will have to install the rmt-server pattern and then configure it . RMT server will need internet connectivity in order to download all the system patches and registry images. 

# su
# zypper lr | grep Server_Applications_Module
SUSEConnect --product sle-module-server-applications/15.1/x86_64
# zypper in rmt-server 
# yast2 rmt
This will take you through rmt-server wizard. You will have to update your respective SCC organization credentials. Also provide values for the DB username and password along with CA password. While creating CA certification provide aliases for charts.example.com and registry.example.com as well . Complete and close the wizard.  

Check the status of the rmt server by issuing below command,

# systemctl status rmt-server.service 

Should return an output similar to below output with Active: active ,  rmt systemd[1]: Started

● rmt-server.service - RMT API server
   Loaded: loaded (/usr/lib/systemd/system/rmt-server.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2020-04-09 20:40:00 IST; 16min ago
 Main PID: 4247 (rails)
    Tasks: 12 (limit: 4915)
   CGroup: /system.slice/rmt-server.service
           └─4247 puma 3.10.0 (tcp://127.0.0.1:4224) [rmt]

Apr 09 20:40:00 rmt systemd[1]: Started RMT API server.

4. Sync anand List all the available products by issuing below command 

# rmt-cli products list --all

This will list the available product repositories to be mirrored offline similar to below output ,

+------+----------------------+---------+--------+--------------+---------------
| ID   | Product              | Version | Arch   | Mirror?      | Last mirrored
+------+----------------------+---------+--------+--------------+---------------
[...]
| 1743 | SUSE Package Hub     | 15      | x86_64 | Don't Mirror |
|      | PackageHub/15/x86_64 |         |        |              |
[...]
The mirror ID can be used to enable or disable a repository . Below repositories must be enabled for our CaaSP and CAP deployment 

| 1772 | Basesystem Module                                  			    | 15 SP1  | x86_64  | 
| 1790 | Containers Module                                   			    | 15 SP1  | x86_64  | 
| 1867 | Python 2 Module                                      			    | 15 SP1  | x86_64  | 
| 1780 | Server Applications Module                			    | 15 SP1  | x86_64  | 
| 1863 | SUSE CaaS Platform                             			    | 4.0         | x86_64  | 
| 1809 | SUSE Cloud Application Platform Tools Module     	    | 15 SP1  | x86_64  |        
| 1763 | SUSE Linux Enterprise Server                     		    | 15 SP1  | x86_64  | 
| 1871 | SUSE Package Hub                           			                | 15 SP1  | x86_64  | 




5.Enable SUSE Cloud Application Platform Tools Module repository with 

# rmt-cli products enable 1809 
should enable the mandatory repositories related to  SUSE Cloud Application Platform Tools Module . The out put should be similar to ,

Found product by target 1809: SUSE Cloud Application Platform Tools Module 15 SP1 x86_64.
Enabling SUSE Cloud Application Platform Tools Module 15 SP1 x86_64:
  SUSE Cloud Application Platform Tools Module 15 SP1 x86_64:
    Enabled repository SLE-Module-CAP-Tools15-SP1-Pool.
    Enabled repository SLE-Module-CAP-Tools15-SP1-Updates.

6. Now mirror the repositories enabled in previous step ,

#  rmt-cli mirror 

The mirror should work without any error .Similarly enable rest of the product repositories mentioned in step 4 ie , rmt-cli products enable 1763 1772 1790 1867 1780 1863 1871 1776 1809 and mirror the same. Mirrored repositories are available under /usr/share/rmt/public/repo/SUSE/Products/ 







































Lab 2: Create offline Docker registry .

1. Install the docker-distribution-registry package on rmt server vm . This package is available in SUSE Packagehub module . 

# zypper refresh 

2. Now install Docker distribution registry 

# zypper install docker docker-distribution-registry

edit docker config file to match below configuration
rmt:~ # cat /etc/registry/config.yml 
version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: 0.0.0.0:5000
  headers:
    X-Content-Type-Options: [nosniff]
  tls:
    certificate: /etc/rmt/ssl/rmt-server.crt
    key: /etc/rmt/ssl/rmt-server.key
health:
  storagedriver:
    enabled: true
    interval: 10s
threshold: 3
*********************************************************************
Note : If your registry is insecure disable registry security verification by editing
/etc/docker/daemon.json to ,
 
{
  "insecure-registries" : ["rmt.example.com:5000"]
}
***********************************************************************************






create the directory registry under /var/lib
# mkdir /var/lib/registry

3. Make sure CA certificate is available to SUSE CaaS system wide 

# cp /etc/rmt/ssl/rmt-ca.crt /etc/pki/trust/anchors/
# update-ca-certificates


4. Enable and start Docker registry on boot
# systemctl enable --now registry

5. Enable and start Docker service on boot  
# systemctl enable --now docker

Now that the offline registry is setup let us test if the registry is working using following steps ,

7. Test image pull 
# docker pull registry.suse.com/suse/sle15:15.1

8. Tag the image 
# docker tag registry.suse.com/suse/sle15:15.1 rmt.example.com:5000/suse/sle15:15.1

9. Push the image to Local repository
# docker push rmt.example.com:5000/suse/sle15:15.1 

Note : above command should result with status pushed . 





















Lab 3:Setup reverse proxy and virtual host 


Login to rmt server .Create a virtual host configuration file /etc/nginx/vhosts.d/registry-server-https.conf . Replace mymirror.local with the hostname of your mirror server for which you created the SSL certificates. 

# vim  /etc/nginx/vhosts.d/registry-server-https.conf

*********************************************************************

upstream docker-registry {
    server 127.0.0.1:5000;
}

map $upstream_http_docker_distribution_api_version $docker_distribution_api_version {
  '' 'registry/2.0';
}

server {
    listen 443   ssl;
    server_name  registry.example.com;

    access_log  /var/log/nginx/registry_https_access.log;
    error_log   /var/log/nginx/registry_https_error.log;
    root        /usr/share/rmt/public;

    ssl_certificate     /etc/rmt/ssl/rmt-server.crt;
    ssl_certificate_key /etc/rmt/ssl/rmt-server.key;
    ssl_protocols       TLSv1.2 TLSv1.3;

    # disable any limits to avoid HTTP 413 for large image uploads
    client_max_body_size 0;

    location /v2/ {
      # Do not allow connections from docker 1.5 and earlier
      # docker pre-1.6.0 did not properly set the user agent on ping, catch "Go *" user agents
      if ($http_user_agent ~ "^(docker\/1\.(3|4|5(?!\.[0-9]-dev))|Go ).*$" ) {
        return 404;
      }

      ## If $docker_distribution_api_version is empty, the header is not added.
      ## See the map directive above where this variable is defined.
      add_header 'Docker-Distribution-Api-Version' $docker_distribution_api_version always;

      proxy_pass                          http://docker-registry;
      proxy_set_header  Host              $http_host;   # required for docker client's sake
      proxy_set_header  X-Real-IP         $remote_addr; # pass on real client's IP
      proxy_set_header  X-Forwarded-For   $proxy_add_x_forwarded_for;
      proxy_set_header  X-Forwarded-Proto $scheme;
      proxy_read_timeout                  900;
    }
}


Create a virtual host configuration file for charts repository /etc/nginx/vhosts.d/charts-server-https.conf .
server {
  listen 443   ssl;
  server_name  charts.example.com;

  access_log  /var/log/nginx/charts_https_access.log;
  error_log   /var/log/nginx/charts_https_error.log;
  root        /srv/www/;

  ssl_certificate     /etc/rmt/ssl/rmt-server.crt;
  ssl_certificate_key /etc/rmt/ssl/rmt-server.key;
  ssl_protocols       TLSv1.2 TLSv1.3;

  location /charts {
    autoindex on;
  }
}

Restart nginx for the changes to take effect.
sudo systemctl restart nginx






















Task 3:Mirror CaaSP and CAP container images to offline registry 

We will need images from registry.suse.com to be mirrored offline for our local repo to work .Official CaaSP and CAP images are listed here , https://documentation.suse.com/external-tree/en-us/suse-caasp/4/skuba-cluster-images.txt 

Login to your rmt server as root and install skopeo and helm-mirror packages . We will use these commands to mirror and copy the content into offline repository

1. Install Helm , Helm-mirror and skopeo . These tools are needed to mirror content from online repositories to Offline registry 

# zypper in helm helm-mirror skopeo

2. Check if the docker service is up and running
# systemctl status docker.service  Should return ,
docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) 
3. Initialize helm and tiller 
# helm init --tiller-image registry.suse.com/caasp/v4/helm-tiller:2.16.1 --service-account tiller
Should initialize helm and tiller with errors . You can ignore the error for now.
4.   Let us create the mirror scripts under /home/tux/HOL1304/ as caasmirror.sh
thirdpartymirror.sh
capmirror.sh
5.  With editor of your choice create caasmirror.sh with below content under *****************
# vim /home/tux/HOL1304/caasmirror.sh 
*******************************************************************************
#!/bin/bash
# "skuba cluster images" to get the latest bootstrap images
MIRROR=rmt.example.com:5000  (This should match the FQDN of your offline registry)
REMOTE="registry.suse.com/caasp/v4"
IMAGES="
hyperkube:v1.16.2
etcd:3.3.15
coredns:1.6.2
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
        docker push $MIRROR/$REMOTE /$IMAGE
    done

***********************************************************************************
6. Now that the mirror is setup execute the caasmirror.sh script
# sh caaspmirror.sh 
Allow the script to complete . Once completed this script will mirror the content of registry.suse.com/caasp/v4 to offline registry  registry.example.com:5000 . 





7.  With editor of your choice create capmirror.sh with following content within ******************
# vim /home/tux/HOL1304/capmirror.sh 
***********************************************************************************
#!/bin/bash
MIRROR="rmt.example.com:5000" #( This should match the FQDN of your offline registry )
REMOTE="registry.suse.com/cap"
IMAGES="
stratos-metrics-firehose-exporter:1.0.0-e913e7f-cap
uaa-mysql:da2b353ab9ef995e526ced5bd6086cb4bf87d982
uaa-uaa:3d27bd075182a032f179e6d7b4c56f0c0dad2c7c
uaa-secret-generation:9021d6d286c72bb28748ec22fb939b51533b8c01
scf-router:e10ca52925930b1530429c37e985631bc67d8e3f
scf-autoscaler-api:54bb8b95df77e1890f1f53a6a873be94d9440b55
scf-nats:b2ce1309ad0723495fa2fcc7307d90ad2a701e2e
scf-log-api:f48a4af4a7b3e6c7dcb6205a0213e5dc7f392169
scf-routing-api:5f091e27556f96d7b6581ce8a592be10b3746d2f
scf-credhub-user:734e499f5bacea3a002c416470e435c2e84c1374
scf-autoscaler-postgres:aa0502af0b603fcdf0ea61721ba4190e92a64bc1
scf-cc-worker:abb781b42300dea81dc3b19cb576799dd0e12496
scf-tcp-router:65be3f63230dd2c5ce953010119b8bb78fbeb091
scf-diego-ssh:202e4a767bbe85bfa0a4ff1cc24b96f822a4d75c
scf-cc-clock:33aa18acfe1f5b3b581adb30c4c568f6a5c5f872
scf-nfs-broker:6a671b91e2182821951105bc30d8ab9506e5af2c
scf-mysql:9bd4d112c280e103a83a8dd77a90674b84f72a93
scf-cf-usb:c29809c2f8e64029268e9d448f59281901d2425f
scf-cc-uploader:1f9ead20bd4b6268a3c8cb3150e5a8d57a371936
scf-post-deployment-setup:d017d46ab32a8d9b913c028f1bf98b3dc9086a0c
scf-syslog-scheduler:a86db5183a5020d78761768459534952cc318a6f
scf-secret-generation:264950e2f99eac71ecdac4310d84578310d09500
scf-diego-brain:c1fc6a6dab4a9c43b742b35a5c11202599f16f4a
scf-blobstore:f7397e573a02230aef520eb39081c9a7a558c74b
scf-doppler:b370ae6b9201603b3c02258aeefb97d21d38627a
scf-diego-cell:b86a68a37ef10a4c0d70be3b1ebc153185bc9e0c
scf-api-group:d0a6d459155cd2beb5494cb6aa22ef02acba8ee7
scf-diego-api:d6aee9d19703e2a538777a1968cf895bd1094b89
scf-autoscaler-actors:a9335a1ebb2338f0fa79a2e474ce1a2221c75025
scf-adapter:a05f1470229de60d6525965430a0c672c205c4ea
scf-autoscaler-metrics:947984d1d0d0070ac7005c1ba815e3607915c8af
stratos-console:2.2.0-c558096-cap
stratos-postflight-job:2.2.0-c558096-cap
stratos-jetstream:2.2.0-c558096-cap
stratos-mariadb:2.2.0-c558096-cap
stratos-metrics-nginx:1.0.0-e913e7f-cap
stratos-metrics-firehose-exporter:1.0.0-e913e7f-cap
stratos-metrics-kube-state-metrics:1.0.0-e913e7f-cap
stratos-metrics-prometheus:1.0.0-e913e7f-cap
stratos-metrics-firehose-init:1.0.0-e913e7f-cap









recipe-downloader:0.30.0
recipe-executor:0.31.0
recipe-uploader:0.28.0
scf-adapter:c306b00f317984c17c7a16e7895e664152754725
scf-api-group:240bba58ea8c6816e874d0df72bec5e6a7288bd8
scf-autoscaler-actors:76a2de51e3236e9bfbfb4037c839a6f966d4ec51
scf-autoscaler-api:6dda56e79f76a07d755acdf5f0787a5f5bb5e0de
scf-autoscaler-metrics:bed854fffa70100254372ec6e860e13ea9131934
scf-autoscaler-postgres:87654c0891279508582d31167ba3552739507b5a
scf-bits:98c80aec4ca157e70004a3e22b08a53fe529e9b8
scf-blobstore:e9843533b9b50c8732c26a1f019c32c0e5d1d026
scf-cc-clock:5979bc5c9f23499889b870eee3a473dadf32c458
scf-cc-uploader:0da2a1e77e892ad37f09c512e34f3f08ec28379d
scf-cc-worker:311734ce2f5a8b3c7d3661233f4ca8f34ec2e399
scf-cf-usb-group:43fd573f368c9298867830eae61503182198005d
scf-configgin-helper:f9d9c2c3d04ad90d1609b7b31b5548979c54b17f
scf-configure-eirini:16243b323f8a90221d32c9fd1e40dea521dc2487
scf-credhub-user:22b8e050b92b3b9f044166460e83a358d3bb34af
scf-diego-api:89981b0a374f50ff4c97558f2c4ea2abf325da8d
scf-diego-brain:d5c5ea22e4535230579c6b25d7b709fa60dc1e4b
scf-diego-cell:735bec6bc52438a4b73b670ad4a4c2959b82ae69
scf-diego-ssh:b5d6f4e69a3d51a6f17618caba4e3352cd6fca7c
scf-doppler:da14867a9ba02904e7986db10b6fb70ad1b6eab5
scf-eirini-persi:8158bc02c4ed40d622fc33ae506ca1ce4ed8ca3f
scf-eirini-ssh:6ca2c078eeb69357b9d5dc901577ebf96e7c994d
scf-eirini:155759633d709645f18b2e3cdced9183d0f0169f
scf-locket:f075cf11061939b5582b2f6cd41defd902f8f8da
scf-log-api:964528e7a74b1cc28bd9b934d30ef28f0fcc1ced
scf-loggregator-agent:98a13dd53091f3cfc60126204d00aa5033ea7e1f
scf-mysql-proxy:3e3d60899c81a9736cb4f36db2d73a8c5a8cc4b7
scf-mysql:d7e00908f08c51769925d5fbaee039ea9282705f
scf-nats:ea3de18b750ca894e7062f7b060a22ee4f019c0e
scf-nfs-broker:fdbf98742036fd626f96fa27539b90bf43845fe3
scf-post-deployment-setup:4d437fbe87dae722cfc235f75cc4f7774b335330
scf-router:4218c48f670db8b16ae19690d1dcf2c44c4312ba
scf-routing-api:099258688e494ba27d13333f98e557bcf90cab5e
scf-secret-generation:9d16624f9a6e8131119e3efbf6ff555f14822ddf
scf-syslog-scheduler:d2aee32c52df5a9a93f34f5e6f729f31b03be7da
scf-tcp-router:821f7f863c989a53ee00d65936360be2c2c05dc7
scf-uaa:c2c5e587774a14e04c429288d10b9a84a42d48c4

"
for IMAGE in ${IMAGES}; do
        echo $IMAGE
        docker pull $REMOTE/$IMAGE
        docker tag $REMOTE/$IMAGE $MIRROR/$IMAGE
        docker push $MIRROR/$IMAGE
    done
***********************************************************************************


8. With editor of your choice edit  nonsuserepo.sh . Check the content of the script ,

# vim /home/tux/HOL1304/nonsuserepo.sh 
*********************************************************************
#!/bin/bash
MIRROR="rmt.example.com:5000" ( This should match the FQDN of your offline registry )
IMAGES="
gcr.io/google_containers/kubernetes-dashboard-amd64:v1.10.0
quay.io/external_storage/nfs-client-provisioner:latest
gcr.io/google_containers/busybox:1.24
mysql:5.6
gcr.io/kubernetes-helm/tiller:v2.8.1
splatform/minibroker:latest
"
for IMAGE in ${IMAGES}; do
        echo $IMAGE
        docker pull $IMAGE
        docker tag $IMAGE $MIRROR/$IMAGE
        docker push $MIRROR/$IMAGE
    done
*********************************************************************
10 . Once the scripts caaspmirror.sh ,capmirror.sh and nonsuserepo.sh are executed without any error , the registries needed to setup offline CaaSP and CAP environment  are mirrored to your local registry . You can verify the offline container images by issuing 
#  docker images 









helm repo add suse https://kubernetes-charts.suse.com/

Task 4 : Mirror helm charts offline 
1. Use helm-mirror to mirror the helm charts to offline location . -
# mkdir /srv/www/charts/
2. chown -R nginx:nginx /srv/www/charts/
3. chmod -R 555 /srv/www/charts/
# helm-mirror --new-root-url http://charts.example.com https://kubernetes-charts.suse.com /srv/www/charts/
Note: --new-root-url will append the local chart repositories URL on the index.yaml file .
2. chown -R nginx:nginx /srv/www/charts/
3. chmod -R 555 /srv/www/charts/
4. Create a virtual host configuration file /etc/nginx/vhosts.d/charts-server-https.conf .

# vim /etc/nginx/vhosts.d/charts-server-https.conf 

server {
  listen 90;
  server_name  charts.example.com;
  access_log  /var/log/nginx/charts_https_access.log;
  error_log   /var/log/nginx/charts_https_error.log;
  root        /srv/www/;
  location /charts {
    autoindex on;
  }
}
5. Restart nginx for the changes to take effect.
# systemctl restart nginx
6. You should be able to access the local charts URL on a browser . Start a tab in your browser and enter  “http://charts.example.com:90/charts/” . You can see the content of charts folder displayed ,

1. Create a directory to mirror charts for offline use
# mkdir /var/lib/rmt/public/charts
2. Change ownership to nginx user
# chown -R _rmt:nginx /var/lib/rmt/public/charts
3. Create soft link to nginx default public directory
# ln -s /var/lib/rmt/public/charts /usr/share/rmt/public/charts
4. Change ownership of soft link to nginx user
chown -R _rmt:nginx /usr/share/rmt/public/charts
5. Use helm-mirror to mirror the helm charts to offline location . --new-root-url will append the local chart repositories URL on the index.yaml file.
# helm-mirror --new-root-url http://charts.example.com https://kubernetes-charts.suse.com /var/lib/rmt/public/charts
6. Open virtual host configuration file /etc/nginx/vhosts.d/rmt-server-http.conf and add the following section as given below: 
# vim /etc/nginx/vhosts.d/rmt-server-http.conf 


location /charts {
        autoindex on;
        access_log  /var/log/nginx/charts_http_access.log;
        error_log   /var/log/nginx/charts_http_error.log;
}

Charts working :
rmt:/usr/share/rmt/public # vim /etc/nginx/vhosts.d/charts-server-https.conf
rmt:/usr/share/rmt/public # ls
repo  suma  tools  v2
rmt:/usr/share/rmt/public # mkdir charts
rmt:/usr/share/rmt/public # chmod 555 charts/
rmt:/usr/share/rmt/public # chmod 555 charts
rmt:/usr/share/rmt/public # chown -R _rmt:nginx charts/
rmt:/usr/share/rmt/public # chown -R _rmt:nginx charts
rmt:/usr/share/rmt/public # ln -s /var/lib/rmt/public/charts /srv/www/charts
rmt:/usr/share/rmt/public # ls -la /srv/www/charts
lrwxrwxrwx 1 root root 26 May  4 20:15 /srv/www/charts -> /var/lib/rmt/public/charts
rmt:/usr/share/rmt/public # touch test.txt /srv/www/charts
rmt:/usr/share/rmt/public # ls -la /srv/www/charts/
total 8
dr-xr-xr-x 2 _rmt nginx 4096 May  4 20:16 .
drwxr-xr-x 6 _rmt nginx 4096 May  4 18:31 ..
-r-xr-xr-x 1 _rmt nginx    0 May  4 18:41 chartxtest.txt
rmt:/usr/share/rmt/public # systemctl restart nginx.service 
rmt:/usr/share/rmt/public # 

Registry working:


Task 5 : Client side changes to access local registry 
We have our RMT server and registry server ready now and we can use them to install SLES and then SUSE CaaSP and CAP. We need to perform below tasks on all SUSE CaaSP cluster machines(master, worker and management nodes).
# cd /etc/pki/trust/anchors
# scp root@rmt.example.com/rmt-ca.crt
# update-ca-certificates
# vim /etc/containers/registries.conf
[[registry]]
location = “registry.suse.com”
mirror = [{ location = “rmt.example.com:5000”}]
## Optional: if the registry is not secure this can be set
## insecure = true
Once everything setup you can follow below link to setup SUSE CaaSP cluster.
https://documentation.suse.com/suse-caasp/4.1/single-html/caasp-deployment/index.html#deployment_bare_metal

# cd /etc/pki/trust/anchors
# scp root@rmt.example.com/rmt-ca.crt
# update-ca-certificates



Once SUSE CaaSP cluster is up and running follow below link to setup SUSE CAP.
https://documentation.suse.com/suse-cap/1.5/single-html/cap-guides/index.html#cha-cap-depl-caasp




