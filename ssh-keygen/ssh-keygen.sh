#!/bin/sh

hosts=`cat ./ihost`
rsa_name="id_rsa"

echo "/------/ ssh-keygen begin. /------/"
for hst in $hosts
do
    echo "------| ssh-keygen for $hst |------"
    ssh root@$hst "if [ -f ~/.ssh/$rsa_name ];then echo '$rsa_name exist'; else ssh-keygen -t rsa -f ~/.ssh/$rsa_name -N ''; fi;"
    #echo 'ssh-agent ssh-add ~/.ssh/$rsa_name' >> ~/.bashrc; source ~/.bashrc;
    echo "/------/($hst) ssh-copy-id for begin. /------/"
    scp root@$hst:/root/.ssh/$rsa_name.pub  /tmp/
    for sechst in $hosts
    do
        echo "------| ssh-copy-id for $sechst |------"
        scp /tmp/$rsa_name.pub root@$sechst:/tmp/
        ssh root@$sechst "cat /tmp/$rsa_name.pub >> ~/.ssh/authorized_keys"
    done
    echo "/------/($hst) ssh-copy-id end. /------/"
done
echo "/------/ ssh-keygen end. /------/"

