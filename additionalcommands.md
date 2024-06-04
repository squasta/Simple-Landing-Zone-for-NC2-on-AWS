# Few commands to check quickly AWS resources

## To list VPC in an AWS region

```bash
aws ec2 describe-vpcs --query 'Vpcs[].{VPC_ID:VpcId,CIDR:CidrBlock,State:State}' --output table
```

## To list EC2 instances in an AWS region

```bash
aws ec2 describe-instances --query 'Reservations[].Instances[].{Instance_ID:InstanceId,Type:InstanceType,State:State.Name}' --output table
```

## To S3 buckets in an AWS region

```bash
aws s3 ls
```


