#!/bin/sh

#import iniparse
. ./iniparse.sh

##defined param
pid=$$
conffile="./conf.ini"
confdir="./conf"
thirdlibdir="./thirdlib"

#create tmp dir
mkdir -p ./tmp

#check conf file
check_syntax $conffile
ck_status=$?

if [ $ck_status != 0 ]
then
    echo "$conffile syntax error(code=$ck_status)."
    kill -9 $pid
fi

#参数获取
luname=$(get_field_value $conffile host luname)
hostlist=$(get_field_value $conffile host hostlist)
hdhome=$(get_field_value $conffile hadoop hdhome)
hddatahome=$(get_field_value $conffile hadoop hddatahome)
zookeeper=$(get_field_value $conffile hadoop zookeeper)
nsclustername=$(get_field_value $conffile hadoop nsclustername)
journalnode=$(get_field_value $conffile hadoop journalnode)
nnhost1=$(get_field_value $conffile hadoop nnhost-1)
nnhost2=$(get_field_value $conffile hadoop nnhost-2)
rmhost1=$(get_field_value $conffile hadoop rmhost-1)
rmhost2=$(get_field_value $conffile hadoop rmhost-2)
mapredhost=$(get_field_value $conffile hadoop mapredhost)
hostarr=(${hostlist//;/ })
hnamelist=()
iplist=()
hosts=()
hoststr=""
idx=0
zkidx=1
zooserver=""
#clear ihost
true > ./ihost

for i in ${hostarr[@]}
do
    tmp=(${i//,/ })
    len=${#tmp[@]}
    if [ $len -gt 1 ]
    then
        iplist[$idx]=${tmp[0]}
        hnamelist[$idx]=${tmp[1]}
        hosts[$idx]="${tmp[0]} ${tmp[1]}"
        hoststr="$hoststr\n${tmp[0]} ${tmp[1]}"
        echo "${iplist[$idx]}" >> ./ihost

        if [[ "$zookeeper" =~ "${hnamelist[$idx]}" ]]
        then
            zooserver="${zooserver}\nserver.${zkidx}=${hnamelist[$idx]}:2888:3888"
            zkidx=$[zkidx+1]
        fi
    fi
    idx=$[idx+1]
done

#免密码登录，执行
sh ./ssh-keygen.sh

#hadoop 配置文件修改
rm -rf ./tmp/conf
cp -r ./conf  ./tmp/
hddatahomepath=${hddatahome//\//\\/}
#core-site config
sed -i "s/#{hddatahome}/${hddatahomepath}/g" ./tmp/conf/core-site.xml
sed -i "s/#{zookeepercluster}/${zookeeper}/g" ./tmp/conf/core-site.xml
sed -i "s/#{nsclustername}/${nsclustername}/g" ./tmp/conf/core-site.xml
#hdfs-site config
sed -i "s/#{hddatahome}/${hddatahomepath}/g" ./tmp/conf/hdfs-site.xml
sed -i "s/#{zookeepercluster}/${zookeeper}/g" ./tmp/conf/hdfs-site.xml
sed -i "s/#{nsclustername}/${nsclustername}/g" ./tmp/conf/hdfs-site.xml
sed -i "s/#{journalnode}/${journalnode}/g" ./tmp/conf/hdfs-site.xml
sed -i "s/#{nnhost-1}/${nnhost1}/g" ./tmp/conf/hdfs-site.xml
sed -i "s/#{nnhost-2}/${nnhost2}/g" ./tmp/conf/hdfs-site.xml
#yarn-site config
sed -i "s/#{hddatahome}/${hddatahomepath}/g" ./tmp/conf/yarn-site.xml
sed -i "s/#{zookeepercluster}/${zookeeper}/g" ./tmp/conf/yarn-site.xml
sed -i "s/#{nsclustername}/${nsclustername}/g" ./tmp/conf/yarn-site.xml
sed -i "s/#{journalnode}/${journalnode}/g" ./tmp/conf/yarn-site.xml
sed -i "s/#{rmhost-1}/${rmhost1}/g" ./tmp/conf/yarn-site.xml
sed -i "s/#{rmhost-2}/${rmhost2}/g" ./tmp/conf/yarn-site.xml
#mapred-site config
sed -i "s/#{hddatahome}/${hddatahomepath}/g" ./tmp/conf/mapred-site.xml
sed -i "s/#{mapredhost}/${mapredhost}/g" ./tmp/conf/mapred-site.xml

#zoo.cfg config
sed -i "s/#{hddatahome}/${hddatahomepath}/g" ./tmp/conf/zoo.cfg

javahome=`echo $JAVA_HOME`
hdconf=`cat hadoopconf`
hdconf=${hdconf//"\$hdhome"/"$hdhome"}
hdconf=${hdconf//"\$hddatahome"/"$hddatahome"}
hdconf=${hdconf//"\$luname"/"$luname"}
hdconf=${hdconf//"\$javahome"/"$javahome"}
hdconf=${hdconf//"\$jhreplace"/"${javahome//\//\\/}"}
hdconf=${hdconf//"\$zookeeper"/"$zookeeper"}
hdconf=${hdconf//"\$hoststr"/"$hoststr"}
#配置
zkidx=1

for ((i=0; i<${#hnamelist[@]}; i++))
do
    hname=${hnamelist[$i]}
    ip=${iplist[$i]}
    newconf=${hdconf//"\$hname"/"$hname"}
    newconf=${newconf//"\$ip"/"$ip"}
    newconf=${newconf//"\$zkidx"/"$zkidx"}
    #echo "----$newconf---"
    scp $thirdlibdir/hadoop/hadoop-2* $luname@${iplist[$i]}:$hdhome/
    scp $thirdlibdir/java/jdk* $luname@${iplist[$i]}:$hdhome/
    scp $thirdlibdir/zookeeper/zookeeper* $luname@${iplist[$i]}:$hdhome/

    ssh $luname@$ip "$newconf"
    
    #zookeeper config;
    if [[ "$zookeeper" =~ "$hname" ]]
    then
        ssh $luname@$ip "rm -rf $hdhome/zookeeper*/*; tar zxf $hdhome/zookeeper*.tar.gz -C $hdhome/ ; mkdir -p ${hddatahome}/storage/zookeeper/; echo '$zkidx' > ${hddatahome}/storage/zookeeper/myid;"
        scp ./tmp/conf/zoo.cfg $luname@$ip:$hdhome/zookeeper*/conf/
        ssh $luname@$ip "echo -e '$zooserver' >> $hdhome/zookeeper*/conf/zoo.cfg"
	zkidx=$[zkidx+1]
    fi
    
    echo -e ""
    #wen jian ti huang
    scp ./tmp/conf/*.xml $luname@$ip:$hdhome/hadoop-2*/etc/hadoop/
    
    #ssh $luname@$ip "$HADOOP_HOME/sbin/hadoop-daemons.sh start journalnode"
done

#qi dong
for hname in ${#hnamelist}
do
    echo ""
done

