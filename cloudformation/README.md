To create the stack: 
```bash
aws --profile tsg cloudformation create-stack --tags "Key=stack,Value=tsg-week2" --template-body file://week-2-cfn-template.yaml --stack-name tsg-week2
```

To delete the stack: 
```bash
aws --profile tsg cloudformation delete-stack --stack-name tsg-week2
```
