### ECR Commands

### log into the registry
```bash
EXPORT JVM_NX_ECR_ID="abc123"
EXPORT AWS_REGION="us-east-1"
EXPORT AWS_PROFILE="some-aws-profile"
aws ecr-public --profile "$AWS_PROFILE" get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin public.ecr.aws/abc123
docker tag jvm-nx-dev:latest docker push gamindev/jvm-nx-dev:latest
docker tag blueocean-dev:latest public.ecr.aws/"$JVM_NX_ECR_ID"/blueocean-dev:latest
```


