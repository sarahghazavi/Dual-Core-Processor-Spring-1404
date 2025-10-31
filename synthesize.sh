#!/bin/bash
set -e
DIR__=$(dirname $0)
python3 "$DIR__/fixboardmap.py" "$1"
"$DIR__/logisim" -f "$1.tmp" main ALCHITRY_AU_IO || echo 
