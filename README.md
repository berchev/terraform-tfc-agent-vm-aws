# terraform-tfc-agent-vm-aws

## Instructions ##
- export credentials
```
$ export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXX
$ export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
$ export AWS_SESSION_TOKEN=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
```
- terraform init
- terraform plan
- terraform apply --auto-approve
- outputs
```
Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

VM1 = "ec2-44-193-5-125.compute-1.amazonaws.com"
```
- SSH to VM
```
ssh -i "~/Dropbox/ec2_key_pair/berchev_key_pair.pem" ubuntu@ec2-44-193-5-125.compute-1.amazonaws.com
```
- Start Agent
```
$ export TFC_AGENT_TOKEN='xxxxxxxxxxxxxx.atlasv1.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
$ export TFC_AGENT_NAME=tfc_agent
$ export TFC_AGENT_LOG_LEVEL=TRACE
$ cd /opt/tfc_agent
$ ./tfc-agent | tee /vagrant/agent_trace.log
```
