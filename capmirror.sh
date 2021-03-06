#!/bin/bash
MIRROR="registry.example.com:5000" 
REMOTE="registry.suse.com/cap"
IMAGES="
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

cf-usb-sidecar-mysql:1.0.1
cf-usb-sidecar-mysql-setup:1.0.1

uaa-configgin-helper:7ef898a83f98f20b3340e88760e99e30c60081c0
uaa-mysql-proxy:797ce1924c85379bf1c83e830955d528597cc832
uaa-mysql:903a2ac9b66484f32137b9029b63ce845695635f
uaa-post-deployment-setup:18a5bef2ffe2f8dc43b47f0fc1c34266c49623cf
uaa-secret-generation:0653dd4863841f90cb585d36907afdfb7c1369bf
uaa-uaa:9de4f84fcaf0672b7488cc0c77342ed955c87e2e
stratos-metrics-cf-exporter:1.1.2-85daaa2-cap
stratos-metrics-firehose-exporter:1.1.2-85daaa2-cap
stratos-metrics-firehose-init:1.1.2-85daaa2-cap
stratos-metrics-nginx:1.1.2-85daaa2-cap
stratos-metrics-configmap-reload:1.1.2-85daaa2-cap
stratos-metrics-init-chown-data:1.1.2-85daaa2-cap
stratos-metrics-kube-state-metrics:1.1.2-85daaa2-cap
stratos-metrics-node-exporter:1.1.2-85daaa2-cap
stratos-metrics-prometheus:1.1.2-85daaa2-cap
minibroker:1b8db9db6bd9b20448599d81dee0ebcd896c1c43
stratos-chartsync:3.0.0-8fbc06b06-cap
stratos-config-init:3.0.0-8fbc06b06-cap
stratos-console:3.0.0-8fbc06b06-cap
stratos-fdbdoclayer:3.0.0-8fbc06b06-cap
stratos-fdbserver:3.0.0-8fbc06b06-cap
stratos-jetstream:3.0.0-8fbc06b06-cap
stratos-mariadb:3.0.0-8fbc06b06-cap
"
for IMAGE in ${IMAGES}; do
        echo $IMAGE
        docker pull $REMOTE/$IMAGE
        docker tag $REMOTE/$IMAGE $MIRROR/$IMAGE
        docker push $MIRROR/$IMAGE
    done
