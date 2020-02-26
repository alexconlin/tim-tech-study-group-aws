To create the stack: aws --profile tsg cloudformation update-stack --tags "Key=stack,Value=tsg-week2" --template-body file://week-2-cfn-template.yaml --stack-name tsg-week2
To delete the stack: aws --profile tsg cloudformation delete-stack --stack-name tsg-week2
