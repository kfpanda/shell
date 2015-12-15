#!/bin/sh

hosts=`cat ./ihost`
rsa_name="id_rsa"

echo "------| ssh-keygen begin. |------"
if [ -f ~/.ssh/$rsa_name ];then 
    echo '$rsa_name exist'; 
else 
    ssh-keygen -t rsa -f ~/.ssh/$rsa_name -N ''; 
fi
echo "------| ssh-keygen end. |------"

ssh-add ~/.ssh/$rsa_name
echo "/------/ ssh-copy-id for begin. /------/"
for hst in $hosts
do
    echo "------| ssh-copy-id for $hst |------"
    ssh-copy-id -i ~/.ssh/$rsa_name.pub root@$hst
done
echo "/------/ ssh-copy-id end. /------/"


