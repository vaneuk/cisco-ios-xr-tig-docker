# TIG Stack with IOS-XR Dashboard example
Copied from repo: https://github.com/dsx1123/telemetry_collector

# How to use
## Install docker
Official ocumentation: https://docs.docker.com/engine/install/ubuntu/

Or refer to snippet [Appendix. Docker installation commands](#appendix-docker-installation-commands)

## Start repo
to quick start, use 
```sudo ./build.sh start```

## ASR Configuration example
```
telemetry model-driven
 destination-group ubuntu
  address-family ipv4 192.168.100.1 port 57000
   encoding self-describing-gpb
   protocol grpc no-tls
  !
 !
 sensor-group cpu
  sensor-path Cisco-IOS-XR-wdsysmon-fd-oper:system-monitoring/cpu-utilization
 !
 sensor-group foo
  sensor-path Cisco-IOS-XR-shellutil-oper:system-time/uptime
  sensor-path Cisco-IOS-XR-infra-statsd-oper:infra-statistics/interfaces/interface/latest/generic-counters
 !
 sensor-group mem
  sensor-path Cisco-IOS-XR-nto-misc-oper:memory-summary/nodes/node/summary
 !
 subscription sub
  sensor-group-id cpu sample-interval 30000
  sensor-group-id foo sample-interval 30000
  sensor-group-id mem sample-interval 30000
  destination-id ubuntu
 !
 ```

# Appendix. Docker installation commands
```
sudo apt-get remove docker docker-engine docker.io containerd runc

sudo apt-get update

 sudo apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

sudo apt-get install docker-ce docker-ce-cli containerd.io

sudo docker run hello-world
```