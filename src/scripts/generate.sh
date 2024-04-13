#! /bin/sh -e

CURRENT_DIR=$(pwd)

cd easy-rsa/easyrsa3
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa --san=DNS:server build-server-full server nopass
./easyrsa build-client-full client nopass

rm -rf $CURRENT_DIR/workdir/
mkdir $CURRENT_DIR/workdir/
cp pki/ca.crt $CURRENT_DIR/workdir/
cp pki/issued/server.crt $CURRENT_DIR/workdir/
cp pki/private/server.key $CURRENT_DIR/workdir/
cp pki/issued/client.crt $CURRENT_DIR/workdir
cp pki/private/client.key $CURRENT_DIR/workdir/

cd $CURRENT_DIR
