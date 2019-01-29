#!/bin/bash -ue

BASEDIR="$(dirname $(readlink -f $0))"

echo BASEDIR="${BASEDIR}"

WIIMU_LOGIN=admin
WIIMU_PASS=admin

function check_install {
  which $1 >/dev/null 2>&1 && return 0 || true
  echo "Please install '"$1"' utility" 1>&2
  if which apt >/dev/null 2>&1; then
    echo "sudo apt install $1" 1>&2
  elif which yum >/dev/null 2>&1; then
    echo "sudo yum install $1" 1>&2
  elif which brew >/dev/null 2>&1; then
    echo "brew install $1" 1>&2
  fi
  exit 1
}

if [ $# -lt 1 ]; then
  echo "Usage: $0 <IP address>" 1>&2
  exit 1
fi

WIIMU_IP=$1

check_install curl 
check_install telnet
check_install expect

echo "Enabling Telnet"

curl http://${WIIMU_IP}/httpapi.asp?command=507269765368656C6C:5f7769696d75645f | grep OK || {
  echo "Cannot enable Telnet on ${WIIMU_IP}" 1>&2
  exit 1
}

sleep 1

echo "Installing startup script"

expect "${BASEDIR}/install_telnet.expect" "${WIIMU_IP}" "${WIIMU_LOGIN}" "${WIIMU_PASS}"

echo "Install OK"

## MANUAL INSTALL
# Run these commands in telnet session to auto-run /vendor/startup.sh 
# on startup

if false
then

cat > /vendor/startup.sh <<EOF
#!/bin/sh
# Uncomment to enable telnet on boot
#/usr/sbin/telnetd &
# Uncomment to disable sleep after 15 minutes
#while true; do sleep 60; echo 'AXX+MUT+000' >/dev/ttyS0; done &
EOF
chmod +x /vendor/startup.sh
nvram_set AIRPLAY_PASSWORD '";/vendor/startup.sh & #'

fi
