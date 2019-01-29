#!/bin/bash

. address.inc
curl -v -o settings.txt http://${WIIMU_ADDRESS}/cgi-bin/ExportSettings.sh
