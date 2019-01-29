#!/bin/bash

. address.inc

curl -v http://${WIIMU_ADDRESS}/httpapi.asp?command=$1
