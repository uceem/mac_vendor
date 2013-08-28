#!/bin/sh

set -e
set -x

OUI_FULL_URL='http://standards.ieee.org/develop/regauth/oui/oui.txt'

curl -o /tmp/oui.txt $OUI_FULL_URL
gzip -9 -c /tmp/oui.txt > data/oui.txt.gz

echo "Update successful.  Remember to update gem version."

