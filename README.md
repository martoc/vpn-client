[![checks](https://github.com/martoc/vpn-client/actions/workflows/checks.yml/badge.svg?branch=main&event=push)](https://github.com/martoc/vpn-client/actions/workflows/checks.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![slack](https://img.shields.io/badge/slack-general-brightgreen.svg?logo=slack)](https://app.slack.com/messages/T8L8AAD3M/C8LBHLSVA)

# vpn-client

An Infrastructure-as-Code (IaC) solution for deploying AWS Client VPN endpoints with mutual TLS authentication. This project provides CloudFormation templates and scripts to establish secure remote access to your AWS VPCs.

## Features

- **Mutual TLS Authentication**: Certificate-based authentication for enhanced security
- **Infrastructure as Code**: Fully automated deployment using AWS CloudFormation
- **Optional VPC Creation**: Use an existing VPC or create a new one with secure defaults
- **Split Tunneling Support**: Configure partial or full VPN routing
- **Multi-Client Support**: Works with AWS VPN Client, OpenVPN Connect, and iOS devices

## Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/martoc/vpn-client.git
   cd vpn-client
   ```

2. **Generate certificates**
   ```bash
   git clone https://github.com/OpenVPN/easy-rsa.git
   src/scripts/generate.sh
   ```

3. **Import server certificate to AWS ACM**
   ```bash
   aws acm import-certificate \
     --certificate fileb://workdir/server.crt \
     --private-key fileb://workdir/server.key \
     --certificate-chain fileb://workdir/ca.crt \
     --region <your-region>
   ```

4. **Deploy the VPN client stack**
   ```bash
   aws cloudformation create-stack \
     --stack-name vpn-client \
     --template-body file://src/cloudformation/vpn-client.yaml \
     --parameters ParameterKey=ServerCertificateArn,ParameterValue=<certificate-arn> \
     --region <your-region>
   ```

See the [full documentation](./docs/index.md) for detailed setup instructions and configuration options.

## Prerequisites

- AWS CLI configured with appropriate credentials
- An AWS account with permissions to create VPC, EC2, and ACM resources
- Git (for cloning easy-rsa)

## Project Structure

```
vpn-client/
├── src/
│   ├── cloudformation/
│   │   ├── vpn-client.yaml    # VPN endpoint CloudFormation template
│   │   └── vpn-vpc.yaml       # Optional VPC CloudFormation template
│   └── scripts/
│       └── generate.sh        # Certificate generation script
└── docs/                      # Documentation
```

## Documentation

- [Getting Started](./docs/INTRODUCTION.md) - Complete setup guide
- [Architecture](./docs/ARCHITECTURE.md) - System design and components
- [Troubleshooting](./docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Code Style](./docs/CODESTYLE.md) - Contribution guidelines

## Security

This project uses certificate-based mutual TLS authentication, which provides stronger security than username/password authentication. For security concerns, please see [SECURITY.md](.github/SECURITY.md).

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](.github/CONTRIBUTING.md) before submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
