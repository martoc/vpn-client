# Troubleshooting

This guide covers common issues and their solutions when deploying and
using AWS Client VPN.

## CloudFormation Deployment Issues

### Stack Creation Failed: Certificate Not Found

**Error:**

```text
Resource handler returned message: "The certificate 'arn:aws:acm:...' ..."
```

**Solution:**

1. Verify the certificate ARN is correct
2. Ensure the certificate is in the same region as the CloudFormation stack
3. List available certificates:

   ```bash
   aws acm list-certificates --region <your-region>
   ```

### Stack Creation Failed: VPC/Subnet Not Found

**Error:**

```text
Resource handler returned message: "The vpc ID 'vpc-xxx' does not exist"
```

**Solution:**

1. If using the `vpn-vpc.yaml` stack, ensure it completed successfully
   before creating `vpn-client`
2. If using an existing VPC, verify the VPC ID:

   ```bash
   aws ec2 describe-vpcs --region <your-region>
   ```

3. Ensure the subnet belongs to the specified VPC:

   ```bash
   aws ec2 describe-subnets \
     --filters "Name=vpc-id,Values=<vpc-id>" \
     --region <your-region>
   ```

### Stack Creation Failed: Import Value Not Found

**Error:**

```text
No export named vpn-vpc-VpcId found
```

**Solution:**

This occurs when deploying `vpn-client.yaml` without first deploying
`vpn-vpc.yaml`, and no explicit VPC parameters were provided.

Either:

1. Deploy the VPC stack first:

   ```bash
   aws cloudformation create-stack --stack-name vpn-vpc \
     --template-body file://src/cloudformation/vpn-vpc.yaml \
     --region <your-region>
   ```

2. Or provide explicit VPC parameters:

   ```bash
   aws cloudformation create-stack --stack-name vpn-client \
     --template-body file://src/cloudformation/vpn-client.yaml \
     --parameters \
       ParameterKey=VpcId,ParameterValue=<vpc-id> \
       ParameterKey=SubnetId,ParameterValue=<subnet-id> \
       ParameterKey=ServerCertificateArn,ParameterValue=<cert-arn> \
     --region <your-region>
   ```

### Stack Stuck in CREATE_IN_PROGRESS

The Client VPN endpoint association can take 5-10 minutes to complete.
If it exceeds 15 minutes:

1. Check CloudFormation events:

   ```bash
   aws cloudformation describe-stack-events \
     --stack-name vpn-client \
     --region <your-region>
   ```

2. If stuck, you may need to delete and recreate:

   ```bash
   aws cloudformation delete-stack \
     --stack-name vpn-client --region <your-region>
   aws cloudformation wait stack-delete-complete \
     --stack-name vpn-client --region <your-region>
   ```

## Certificate Issues

### Certificate Generation Failed

**Error:**

```text
easy-rsa not found
```

**Solution:**

Clone easy-rsa to the project root:

```bash
git clone https://github.com/OpenVPN/easy-rsa.git
```

### Certificate Import Failed

**Error:**

```text
Could not find a required AWS Signature Version 4 signing key
```

**Solution:**

Ensure AWS CLI is properly configured:

```bash
aws configure
# Or use environment variables
export AWS_ACCESS_KEY_ID=<key>
export AWS_SECRET_ACCESS_KEY=<secret>
export AWS_DEFAULT_REGION=<region>
```

### Certificate Chain Error

**Error:**

```text
The certificate chain is invalid
```

**Solution:**

Ensure you're importing in the correct order:

```bash
aws acm import-certificate \
  --certificate fileb://workdir/server.crt \
  --private-key fileb://workdir/server.key \
  --certificate-chain fileb://workdir/ca.crt \
  --region <your-region>
```

## VPN Connection Issues

### Connection Timeout

**Symptoms:**

- Client shows "Connecting..." indefinitely
- Connection times out after 30-60 seconds

**Possible Causes and Solutions:**

1. **Security Group blocking traffic**

   Verify the VPN security group allows inbound UDP 443:

   ```bash
   aws ec2 describe-security-groups \
     --group-ids <security-group-id> \
     --region <your-region>
   ```

2. **Endpoint not associated with subnet**

   Check endpoint associations in the AWS Console.
   Verify the association completed successfully.

3. **Network ACL blocking traffic**

   If using `vpn-vpc.yaml`, NACLs are pre-configured.
   For existing VPCs, ensure UDP 443 is allowed.

### Authentication Failed

**Symptoms:**

- "TLS handshake failed"
- "Certificate verification failed"

**Solutions:**

1. **Client certificate not in config file**

   Ensure `<cert>` and `<key>` sections are added to the `.ovpn` file.
   Verify certificate content is complete (including BEGIN/END markers).

2. **Certificate mismatch**

   Client certificate must be signed by the same CA as the server
   certificate. Regenerate certificates if needed:

   ```bash
   rm -rf workdir easy-rsa
   git clone https://github.com/OpenVPN/easy-rsa.git
   src/scripts/generate.sh
   ```

3. **Expired certificate**

   Check certificate expiration:

   ```bash
   openssl x509 -in workdir/client.crt -noout -dates
   ```

### Connected But No Network Access

**Symptoms:**

- VPN shows connected
- Cannot ping or access VPC resources
- Cannot access internet

**Solutions:**

1. **Authorization rules missing**

   Verify authorization rules exist:

   ```bash
   aws ec2 describe-client-vpn-authorization-rules \
     --client-vpn-endpoint-id <endpoint-id> \
     --region <your-region>
   ```

2. **Route table issues**

   Check VPN routes:

   ```bash
   aws ec2 describe-client-vpn-routes \
     --client-vpn-endpoint-id <endpoint-id> \
     --region <your-region>
   ```

3. **Split tunnel configuration**

   If `SplitTunnel=true`, only VPC traffic goes through VPN.
   For full internet access through VPN, set `SplitTunnel=false`.

4. **VPC routing issues**

   Ensure the VPC route table has a route to the Internet Gateway.
   Check that the subnet is associated with the correct route table.

### DNS Resolution Not Working

**Symptoms:**

- Can ping IP addresses but not hostnames
- DNS queries fail

**Solutions:**

1. **Use VPC DNS**

   The VPN endpoint should push VPC DNS settings.
   If using custom DNS, ensure it's accessible from the VPN.

2. **Check DNS settings**

   Verify DNS settings on the VPN endpoint in AWS Console.
   Default is to use VPC DNS servers.

## iOS-Specific Issues

### Profile Import Failed

**Solution:**

- Ensure the `.ovpn` file is valid UTF-8
- Remove any Windows line endings:

  ```bash
  sed -i 's/\r$//' client-config.ovpn
  ```

### Connection Drops Frequently

**Solutions:**

1. Enable "Seamless Tunnel" in OpenVPN Connect settings
2. Check iOS battery optimization settings
3. Ensure stable internet connection

## Cleanup

### Delete All Resources

To completely remove the VPN infrastructure:

```bash
# Delete VPN client stack first
aws cloudformation delete-stack \
  --stack-name vpn-client --region <your-region>
aws cloudformation wait stack-delete-complete \
  --stack-name vpn-client --region <your-region>

# Delete VPC stack (if created)
aws cloudformation delete-stack \
  --stack-name vpn-vpc --region <your-region>
aws cloudformation wait stack-delete-complete \
  --stack-name vpn-vpc --region <your-region>

# Delete certificate from ACM
aws acm delete-certificate \
  --certificate-arn <certificate-arn> --region <your-region>

# Clean up local files
rm -rf workdir easy-rsa
```

## Getting Help

If you encounter issues not covered here:

1. Check [AWS Client VPN Documentation][aws-vpn-docs]
2. Review CloudFormation stack events for detailed error messages
3. Open an issue on the [GitHub repository][github-issues]

[aws-vpn-docs]: https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/
[github-issues]: https://github.com/martoc/vpn-client/issues
