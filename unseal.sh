#!/bin/bash

file=/etc/vault/init.file

vault status

if [ ! -f $file ]; then
  echo -e "\n ...Init and unseal\n"
  sleep 2
  vault operator init > $file
  for i in $(cat $file | grep Key | cut -d ":" -f2); do vault operator unseal $i; done
else
  echo -e "\n..Have already been initialized, 
  if need to re-inialize, delete your storage-backend data and $file 
  then run this script again..\n"
fi

