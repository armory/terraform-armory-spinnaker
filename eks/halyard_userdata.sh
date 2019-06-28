#!/bin/bash
set -e
set -x

if [[ $(sudo file -s /dev/nvme0n1 | awk '{print $NF}') == 'data' ]];
then
  echo "Formatting /dev/nvme0n1 as ext4"
  sudo mkfs -t ext4 /dev/nvme0n1
elif [[ $(sudo file -s /dev/nvme0n1 | grep ext4 | wc -l) -eq 1 ]];
then
  echo "Detected existing ext4 filesystem on /dev/nvme0n1"
else
  echo "Something is wrong - other file system detected on /dev/nvme0n1"
  exit 1
fi

sudo mkdir -p /etc/halyard
echo "UUID=$(sudo blkid -o value -s UUID /dev/nvme0n1)    /etc/halyard    ext4 defaults    0 0" | sudo tee -a /etc/fstab
mount -a

# Clean up later - permissions mismatch
sudo mkdir -p /etc/halyard/.hal
sudo mkdir -p /etc/halyard/.hal/secret
chown -R 100.65533 /etc/halyard/.hal

sudo apt-get update
sudo apt-get install -y \
  python3-pip \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo pip3 install awscli --upgrade

docker run --name armory-halyard --rm \
    -v /etc/halyard/.hal:/home/spinnaker/.hal \
    -d docker.io/armory/halyard-armory:1.6.2

curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl \
  -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

curl -L https://amazon-eks.s3-us-west-2.amazonaws.com/1.13.7/2019-06-11/bin/linux/amd64/aws-iam-authenticator \
  -o /usr/local/bin/aws-iam-authenticator \
  && chmod +x /usr/local/bin/aws-iam-authenticator

curl -L https://github.com/armory/spinnaker-tools/releases/download/0.0.6/spinnaker-tools-linux \
  -o /usr/local/bin/spinnaker-tools \
  && chmod +x /usr/local/bin/spinnaker-tools

CLUSTER_NAME=terraform-armory-spinnaker
REGION=us-east-1
SOURCE_KUBECONFIG=/root/kubeconfig
aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER_NAME}
aws eks --region ${REGION} update-kubeconfig --name ${CLUSTER_NAME} --kubeconfig /root/kubeconfig

CONTEXT=$(kubectl --kubeconfig ${SOURCE_KUBECONFIG} config current-context)
DEST_KUBECONFIG=/etc/halyard/.hal/secret/kubeconfig-spinnaker-sa
SPINNAKER_NAMESPACE=spinnaker
SERVICE_ACCOUNT_NAME=spinnaker-service-account

spinnaker-tools create-service-account \
  --kubeconfig ${SOURCE_KUBECONFIG} \
  --context ${CONTEXT} \
  --output ${DEST_KUBECONFIG} \
  --namespace ${SPINNAKER_NAMESPACE} \
  --service-account-name ${SERVICE_ACCOUNT_NAME}

while [[ $(docker exec -it armory-halyard netstat -plnt | grep 8064 | wc -l) -lt 1 ]];
do 
  echo 'Waiting for Halyard to start'
  sleep 2
done