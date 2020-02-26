#!/usr/bin/env bash
set -euxo pipefail # exit unset print pipefail

vpc_id="$(aws --profile tsg ec2 create-vpc --cidr-block 10.10.0.0/16 --query 'Vpc.VpcId' --output text)"
subnet_id_a="$(aws --profile tsg ec2 create-subnet --vpc-id "$vpc_id" --cidr-block 10.10.0.0/24 --availability-zone eu-west-1a --query 'Subnet.SubnetId' --output text)"
subnet_id_b="$(aws --profile tsg ec2 create-subnet --vpc-id "$vpc_id" --cidr-block 10.10.1.0/24 --availability-zone eu-west-1b --query 'Subnet.SubnetId' --output text)"
aws --profile tsg ec2 modify-subnet-attribute --subnet-id "$subnet_id_a" --map-public-ip-on-launch
aws --profile tsg ec2 modify-subnet-attribute --subnet-id "$subnet_id_b" --map-public-ip-on-launch
internet_gateway_id="$(aws --profile tsg ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)"
aws --profile tsg ec2 attach-internet-gateway --internet-gateway-id "$internet_gateway_id" --vpc-id "$vpc_id"
route_table_id="$(aws --profile tsg ec2 create-route-table --vpc-id "$vpc_id" --query 'RouteTable.RouteTableId' --output text)"
aws --profile tsg ec2 associate-route-table --route-table-id "$route_table_id" --subnet-id "$subnet_id_a"
aws --profile tsg ec2 associate-route-table --route-table-id "$route_table_id" --subnet-id "$subnet_id_b"
aws --profile tsg ec2 create-route --route-table-id "$route_table_id" --destination-cidr-block 0.0.0.0/0 --gateway-id "$internet_gateway_id"

security_group_id="$(aws --profile tsg ec2 create-security-group --vpc-id "$vpc_id" --description 'public http' --group-name 'public-http' --query 'GroupId' --output text)"
aws --profile tsg ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 80 --cidr 0.0.0.0/0 
aws --profile tsg ec2 authorize-security-group-ingress --group-id "$security_group_id" --protocol tcp --port 22 --cidr "$(curl curlmyip.org)/32"

# everything above here can be deleted by deleting the VPC in the console

load_balancer_arn="$(aws --profile tsg elbv2 create-load-balancer --name myalb --subnets "$subnet_id_a" "$subnet_id_b" --security-groups "$security_group_id" --query 'LoadBalancers[0].LoadBalancerArn' --output text)"
target_group_arn="$(aws --profile tsg elbv2 create-target-group --name ec2-targets --protocol HTTP --port 80 --vpc-id "$vpc_id" --query 'TargetGroups[0].TargetGroupArn' --output text)"
aws --profile tsg elbv2 create-listener --load-balancer-arn "$load_balancer_arn" --protocol HTTP --port 80 --default-actions "Type=forward,TargetGroupArn=$target_group_arn"

image_id="$(aws --profile tsg ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" "Name=virtualization-type,Values=hvm" --query 'reverse(sort_by(Images, &CreationDate))[1].ImageId' --output text)"
aws --profile tsg ec2 describe-instance-types --query 'InstanceTypes[?FreeTierEligible].InstanceType'

instance_id_a="$(aws --profile tsg ec2 run-instances --subnet-id "$subnet_id_a" --image-id "$image_id" --instance-type t2.micro --security-group-id "$security_group_id" --user-data '#!/bin/bash\nmkdir -p /var/www\necho "<html><body><h1>Hello Tech Study Group</h1>Are you having fun yet?<h2><div><img src="http://share.conlinoakley.com/7666z8ahw8v.png"></div>This hilarious message served by EC2 instance @ ${HOSTNAME} in an availability zone of $(ec2-metadata -z)</h2></body></html>" > /var/www/index.html\ncd /var/www\npython -m SimpleHTTPServer')"
aws --profile tsg elbv2 register-targets --target-group-arn "$target_group_arn" --targets "Id=$instance_id_a,Port=8000"

instance_id_b="$(aws --profile tsg ec2 run-instances --subnet-id "$subnet_id_b" --image-id "$image_id" --instance-type t2.micro --security-group-id "$security_group_id" --user-data '#!/bin/bash\nmkdir -p /var/www\necho "<html><body><h1>Hello Tech Study Group</h1>Are you having fun yet?<h2><div><img src="http://share.conlinoakley.com/7666z8ahw8v.png"></div>This hilarious message served by EC2 instance @ ${HOSTNAME} in an availability zone of $(ec2-metadata -z)</h2></body></html>" > /var/www/index.html\ncd /var/www\npython -m SimpleHTTPServer')"
aws --profile tsg elbv2 register-targets --target-group-arn "$target_group_arn" --targets "Id=$instance_id_b,Port=8000"
