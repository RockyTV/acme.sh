#!/usr/bin/env sh

# Deploy Let's Encrypt certs to ZNC
#
# Any non-zero returns means something wrong has occurred

_ZNC_DIR="/var/lib/znc/.znc"
_ZNC_USER="znc"

########  Public functions #####################

#domain keyfile certfile cafile fullchain
znc_deploy() {
  _cdomain="$1"
  _ckey="$2"
  _ccert="$3"
  _cca="$4"
  _cfullchain="$5"

  # Allow users to override the default ZNC user
  if [ -n "$ZNC_USER" ]; then
    _ZNC_USER="$ZNC_USER"
    _info "ZNC user set to: $_ZNC_USER"
  fi

  # Check if acme.sh is running as the ZNC user
  # This is required to not use chown and change the certificates permissions
  _curr_user="$(id -u -n)"
  if [ $_curr_user != $_ZNC_USER ]; then
    _err "acme.sh must be run by the ZNC user."
    _err "Please run acme.sh as: $_ZNC_USER"
    return 1
  fi

  # Allow users to override the default ZNC config dir
  if [ -n "$ZNC_DIR" ]; then
    _ZNC_DIR="$ZNC_DIR"
    _info "ZNC config path set to: $_ZNC_DIR"

    # Check if the specified ZNC config dir is owned by the specified ZNC user
    if [ -z "$(find . -user "$_ZNC_USER" -print -prune -o -prune)" ]; then
      _err "The specified ZNC config directory isn't owned by $_ZNC_USER"
      _err "Please specify the correct directory or correct user"
      return 2
    fi
  fi

  # Save ZNC user and config directory to account.conf
   _saveaccountconf ZNC_USER "$_ZNC_USER"
   _saveaccountconf ZNC_DIR "$_ZNC_DIR"

  # ZNC certificate file location
  _znc_cert="$_ZNC_DIR/znc.pem"

  # Please read https://wiki.znc.in/Signed_SSL_certificate
  _info "Generating ZNC certificate file for $_cdomain"
  cat "$_ckey" > "$_znc_cert"
  cat "$_ccert" >> "$_znc_cert"
  cat "$_cca" >> "$_znc_cert"

  _info "Successfully generated ZNC certificate file at: $_znc_cert"
  return 0
}
