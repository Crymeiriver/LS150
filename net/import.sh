#!/bin/bash

. address.inc

#FIXME
curl -v -v -F "filename=@settings.txt" http://${WIIMU_ADDRESS}/cgi-bin/upload_settings.cgi
