#!/bin/bash

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

DATE=$(date +"%Y%m%d")
EMAIL="chris@chriscohen.dev"

while ! mail -s "S.M.A.R.T. Logs $DATE" $EMAIL < smartlog
do
  sleep 5
done

rm smartlog
