# Introduction

You need a VPC in AWS and a VPN client to connect to the VPC. This document describes how to create a VPC and VPN client configuration in AWS.

## Create VPC (Optional)

An existing VPC could be used to create the VPN client. If you don't have a VPC, you can create one using the following command:

```bash
aws cloudformation create-stack --stack-name vpn-vpc --template-body file://src/cloudformation/vpn-vpc.yaml --region us-east-2
```

## Create certificates for multual TLS

This document describes how to create certificates for mutual TLS. The same certificate could be used in multiple regions.

```bash
git clone https://github.com/OpenVPN/easy-rsa.git
src/scripts/generate.sh
```

## Import certificates into AWS ACM

```bash
aws acm import-certificate --certificate fileb://workdir/server.crt --private-key fileb://workdir/server.key --certificate-chain fileb://workdir/ca.crt --region us-east-2
```

## Create vpn-client stack

```bash
aws cloudformation create-stack --stack-name vpn-client --template-body file://src/cloudformation/vpn-client.yaml --parameters "ParameterKey=ServerCertificateArn,ParameterValue=arn:aws:acm:*******:************:certificate/*********-****-****-****-*************" --region us-east-2
```

## Configure AWS VPN Client

* Download the configuration file from the AWS Console
* Update the configuration file with the client certificate `workdir/client.crt` and client key `workdir/client.key` adding this section to the configuration file below the `<ca></ca>` section
```
<cert>
-----BEGIN CERTIFICATE-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
....
-----END CERTIFICATE-----
</cert>

<key>
-----BEGIN PRIVATE KEY-----
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
....
-----END PRIVATE KEY-----
```
* In your local install the [AWS VPN client](https://aws.amazon.com/vpn/client-vpn-download/)
* Configure the OpenVPN client with the configuration file
* Connect to the VPN

## Connect your iOS device to the VPN (Optional)

* Download [OpenVPN Connect](https://apps.apple.com/us/app/openvpn-connect-openvpn-app/id590379981) from the App Store
* Share the configuration file with the iOS device and open it with OpenVPN Connect
* Provide a name to the connection and save it
* Connect to the VPN

