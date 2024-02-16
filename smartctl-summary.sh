#!/bin/bash

source $(dirname "$0")/.env
DATE=$(date +"%Y%m%d")


touch smartlog
echo "------------------------------ /dev/sda ------------------------------" >> smartlog
echo >> smartlog
smartctl -a /dev/sda >> smartlog

echo >> smartlog
echo "------------------------------ /dev/sdb ------------------------------" >> smartlog
echo >> smartlog
smartctl -a /dev/sdb >> smartlog 

echo >> smartlog
echo "------------------------------ /dev/sdc ------------------------------" >> smartlog
echo >> smartlog
smartctl -a /dev/sdc >> smartlog

echo >> smartlog
echo "------------------------------ /dev/sdd ------------------------------" >> smartlog
echo >> smartlog
smartctl -a /dev/sdd >> smartlog

while ! mail -s "S.M.A.R.T. Logs $DATE" $EMAIL < smartlog
do
  sleep 5
done

rm smartlog
