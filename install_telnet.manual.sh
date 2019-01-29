exit 0

## MANUAL INSTALL
# Run these commands in telnet session to auto-run /vendor/startup.sh 
# on startup

cat > /vendor/startup.sh <<EOF
#!/bin/sh
# Start telnet on every boot
/usr/sbin/telnetd &
# Disable device sleep after 15 minutes of inactivity
while true; do sleep 60; echo 'AXX+MUT+000' >/dev/ttyS0; done &
EOF
chmod +x /vendor/startup.sh
nvram_set AIRPLAY_PASSWORD '";/vendor/startup.sh & #'
