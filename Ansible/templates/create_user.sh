#!/bin/bash

# {{ ansible_managed }}

source /home/ubuntu/openvpn-ca/vars

# OpenVPN configuration Directory
OPENVPN_CFG_DIR=/etc/openvpn

# Where this script should create the OpenVPN client config files
OUTPUT_DIR=/home/ubuntu/client-configs

# Base configuration for the client
BASE_CONFIG=/home/ubuntu/client-configs/base.conf

# MFA Label
MFA_LABEL='OpenVPN Server'

# MFA User
MFA_USER=root

# MFA Directory
MFA_DIR=/etc/openvpn/google-authenticator



function build_key() {
  user_id=$1
  $EASY_RSA/pkitool $user_id
}


function generate_mfa() {
  user_id=$1

  if [ "$user_id" == "" ]; then
    echo "ERROR: No user id provided to generate MFA token"
    exit 1
  fi

  echo "INFO: Creating user ${user_id}"
  useradd -s /bin/nologin "$user_id"

  echo "> Please provide a password for the user"
  passwd "$user_id"

  echo "INFO: Generating MFA Token"
 # google-authenticator -t -d -r3 -R30 -f -l "${MFA_LABEL}" -s $MFA_DIR/${user_id}
 # chown $MFA_USER $MFA_DIR/${user_id}
}

function main() {
  user_id=$1

  if [ "$user_id" == "" ]; then
    echo "ERROR: No user id provided"
    exit 1
  fi

  build_key $user_id

  if [ ! -f ${KEY_DIR}/ca.crt ]; then
    echo "ERROR: CA certificate not found"
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/${user_id}.crt ]; then
    echo "ERROR: User certificate not found"
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/${user_id}.key ]; then
    echo "ERROR: User private key not found"
    exit 1
  fi

  if [ ! -f ${KEY_DIR}/ta.key ]; then
    echo "ERROR: TLS Auth key not found"
    exit 1
  fi

  cat ${BASE_CONFIG} \
      <(echo -e '<ca>') \
      ${KEY_DIR}/ca.crt \
      <(echo -e '</ca>\n<cert>') \
      ${KEY_DIR}/${user_id}.crt \
      <(echo -e '</cert>\n<key>') \
      ${KEY_DIR}/${user_id}.key \
      <(echo -e '</key>\n<tls-auth>') \
      ${KEY_DIR}/ta.key \
      <(echo -e '</tls-auth>') \
      > ${OUTPUT_DIR}/${user_id}.ovpn

  echo "INFO: Key created in ${OUTPUT_DIR}/${user_id}.ovpn"

  generate_mfa $user_id

  exit 0
}

# ##############################################################################

main $1