# Getting Started

This guide walks you through setting up an AWS Client VPN endpoint to securely connect to your AWS VPC from anywhere.

## Overview

AWS Client VPN is a managed client-based VPN service that enables secure access to AWS resources and on-premises networks. This project automates the deployment using CloudFormation templates and provides scripts for certificate generation.

## Prerequisites

Before you begin, ensure you have:

- **AWS CLI**: Installed and configured with credentials that have permissions to:
  - Create and manage CloudFormation stacks
  - Create VPCs, subnets, and security groups
  - Import certificates to AWS Certificate Manager (ACM)
  - Create Client VPN endpoints
- **Git**: For cloning the easy-rsa repository
- **Bash**: For running the certificate generation script

## Step 1: Create a VPC (Optional)

You can use an existing VPC or create a new one using the provided CloudFormation template.

### Option A: Use the Provided VPC Template

The `vpn-vpc.yaml` template creates a VPC with secure defaults including:
- A public subnet with Internet Gateway
- Network ACLs that block SSH/RDP access
- DNS support enabled

```bash
aws cloudformation create-stack \
  --stack-name vpn-vpc \
  --template-body file://src/cloudformation/vpn-vpc.yaml \
  --region <your-region>
```

**Available Parameters:**

| Parameter | Default | Description |
|-----------|---------|-------------|
| VPCName | vpn-vpc | Name tag for the VPC |
| VPCCidr | 10.0.0.0/20 | CIDR block for the VPC |
| PublicSubnetCidr | 10.0.0.0/24 | CIDR block for the public subnet |
| UseAwsDns | true | Use AWS-provided DNS |

Wait for the stack to complete:

```bash
aws cloudformation wait stack-create-complete \
  --stack-name vpn-vpc \
  --region <your-region>
```

### Option B: Use an Existing VPC

If you have an existing VPC, note down the following values:
- **VPC ID**: e.g., `vpc-0123456789abcdef0`
- **Subnet ID**: e.g., `subnet-0123456789abcdef0`
- **VPC CIDR Block**: e.g., `10.0.0.0/16`

## Step 2: Generate Certificates for Mutual TLS

AWS Client VPN uses mutual TLS authentication, requiring both server and client certificates.

### Clone easy-rsa

```bash
git clone https://github.com/OpenVPN/easy-rsa.git
```

### Generate Certificates

Run the provided script to generate all required certificates:

```bash
src/scripts/generate.sh
```

This creates the following files in the `workdir/` directory:

| File | Purpose |
|------|---------|
| `ca.crt` | Certificate Authority certificate |
| `server.crt` | Server certificate |
| `server.key` | Server private key |
| `client.crt` | Client certificate |
| `client.key` | Client private key |

> **Security Note**: The generated certificates use the `nopass` option for convenience. In production environments, consider using password-protected keys and a proper PKI infrastructure.

## Step 3: Import Server Certificate to AWS ACM

Import the server certificate to AWS Certificate Manager:

```bash
aws acm import-certificate \
  --certificate fileb://workdir/server.crt \
  --private-key fileb://workdir/server.key \
  --certificate-chain fileb://workdir/ca.crt \
  --region <your-region>
```

**Save the certificate ARN** from the output. It will look like:
```
arn:aws:acm:us-east-2:123456789012:certificate/12345678-1234-1234-1234-123456789012
```

You can also retrieve it later:

```bash
aws acm list-certificates --region <your-region>
```

## Step 4: Deploy the VPN Client Stack

### Using the VPC Created in Step 1

If you used the `vpn-vpc.yaml` template, the VPN client stack will automatically import the VPC and subnet IDs:

```bash
aws cloudformation create-stack \
  --stack-name vpn-client \
  --template-body file://src/cloudformation/vpn-client.yaml \
  --parameters \
    ParameterKey=ServerCertificateArn,ParameterValue=<certificate-arn> \
  --region <your-region>
```

### Using an Existing VPC

If using your own VPC, provide the VPC details:

```bash
aws cloudformation create-stack \
  --stack-name vpn-client \
  --template-body file://src/cloudformation/vpn-client.yaml \
  --parameters \
    ParameterKey=ServerCertificateArn,ParameterValue=<certificate-arn> \
    ParameterKey=VpcId,ParameterValue=<vpc-id> \
    ParameterKey=SubnetId,ParameterValue=<subnet-id> \
    ParameterKey=VpcCidrBlock,ParameterValue=<vpc-cidr> \
  --region <your-region>
```

### Available Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| ServerCertificateArn | (required) | ARN of the server certificate in ACM |
| VpcId | (imported) | VPC ID (if not using vpn-vpc stack) |
| SubnetId | (imported) | Subnet ID for VPN association |
| VpcCidrBlock | 10.0.0.0/20 | CIDR block of the VPC |
| ClientCidrBlock | 172.16.0.0/12 | CIDR range for VPN clients |
| SplitTunnel | false | Enable split tunneling |

Wait for the stack to complete:

```bash
aws cloudformation wait stack-create-complete \
  --stack-name vpn-client \
  --region <your-region>
```

## Step 5: Configure the VPN Client

### Download the Configuration File

1. Open the [AWS VPC Console](https://console.aws.amazon.com/vpc/)
2. Navigate to **Client VPN Endpoints**
3. Select your endpoint
4. Click **Download Client Configuration**
5. Save the `.ovpn` file

### Add Client Certificate and Key

Edit the downloaded `.ovpn` file and add your client certificate and key below the `</ca>` section:

```
<cert>
-----BEGIN CERTIFICATE-----
[Contents of workdir/client.crt]
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
[Contents of workdir/client.key]
-----END PRIVATE KEY-----
</key>
```

You can use this command to append the certificates:

```bash
echo "" >> client-config.ovpn
echo "<cert>" >> client-config.ovpn
cat workdir/client.crt >> client-config.ovpn
echo "</cert>" >> client-config.ovpn
echo "" >> client-config.ovpn
echo "<key>" >> client-config.ovpn
cat workdir/client.key >> client-config.ovpn
echo "</key>" >> client-config.ovpn
```

### Connect Using AWS VPN Client

1. Download and install the [AWS VPN Client](https://aws.amazon.com/vpn/client-vpn-download/)
2. Open AWS VPN Client
3. Go to **File** > **Manage Profiles**
4. Click **Add Profile**
5. Select your configuration file
6. Click **Connect**

## iOS Setup (Optional)

To connect from an iOS device:

1. Download [OpenVPN Connect](https://apps.apple.com/us/app/openvpn-connect-openvpn-app/id590379981) from the App Store
2. Transfer the configured `.ovpn` file to your device:
   - Use AirDrop
   - Email it to yourself
   - Use a cloud storage service
3. Open the file with OpenVPN Connect
4. Tap **Add** to import the profile
5. Give the connection a name and save
6. Toggle the connection to connect

## Verify Connection

Once connected, verify your VPN connection:

```bash
# Check your IP address (should show VPN endpoint IP for full tunnel)
curl ifconfig.me

# Test connectivity to resources in your VPC
ping <private-ip-of-ec2-instance>
```

## Next Steps

- [Architecture Guide](./ARCHITECTURE.md) - Understand the system design
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions
- [AWS Client VPN Documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/) - Official AWS documentation
