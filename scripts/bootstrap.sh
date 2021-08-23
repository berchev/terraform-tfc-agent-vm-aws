#!/usr/bin/env bash

#Debug mode enabled 
#set -x


# Install specific Terraform version. Desired Version -> format x.y.z
TERRAFORM_VERSION="1.0.5"

[ -f "/usr/local/bin/terraform" ] || {
  pushd /usr/local/bin
  TERRAFORM_URL=$(curl -sL https://releases.hashicorp.com/terraform/index.json | jq -r '.versions[].builds[].url' | egrep 'terraform_[0-9]\.[0-9]{1,2}\.[0-9]{1,2}_linux.*amd64' | grep $TERRAFORM_VERSION)
  curl -o terraform.zip $TERRAFORM_URL
  unzip terraform.zip
  rm -f terraform.zip
  popd
}

# Install specific TFC AGENT version. Desired Version -> format x.y.z
TFC_AGENT_VERSION="0.4.0"

[ -d "/opt/tfc_agent" ] || {
  mkdir /opt/tfc_agent
  pushd /opt/tfc_agent
  TERRAFORM_AGENT_URL=$(curl -sL https://releases.hashicorp.com/tfc-agent/index.json | jq -r '.versions[].builds[].url' | egrep 'tfc-agent_[0-9]\.[0-9]{1,2}\.[0-9]{1,2}' | grep $TFC_AGENT_VERSION)
  curl -o tfc_agent.zip $TERRAFORM_AGENT_URL
  unzip tfc_agent.zip
  rm -f tfc_agent.zip
  popd
}
