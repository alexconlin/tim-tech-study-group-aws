SHELL := /bin/bash
bucket=wildrydes-alexconlin

.PHONY: create
create:
	aws --profile tsg cloudformation create-stack --tags "Key=stack,Value=tsg-wildrydes" --template-body file://all-modules-template.yaml --stack-name tsg-wildrydes --parameters ParameterKey=BucketName,ParameterValue=$(bucket) --capabilities CAPABILITY_NAMED_IAM
	aws --profile tsg cloudformation wait stack-create-complete --stack-name tsg-wildrydes
	echo "Wild Rydes is now available at: $$(aws --profile tsg cloudformation describe-stacks --stack-name tsg-wildrydes --output text --query 'Stacks[0].Outputs[0].OutputValue')"

.PHONY: delete
delete:
	aws --profile tsg cloudformation delete-stack --stack-name tsg-wildrydes
	aws --profile tsg cloudformation wait stack-delete-complete --stack-name tsg-wildrydes
