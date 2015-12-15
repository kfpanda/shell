hosts=`cat ./ihost`
1、设置hostname
sed -i 's/^HOSTNAME=.*/HOSTNAME=HD-1/g' /etc/sysconfig/network
sysctl kernel.hostname=HD-1

echo '' >> /etc/hosts
echo '### hadoop hosts  begin' >> /etc/hosts
echo '172.30.1.238   HD-1' >> /etc/hosts
echo '172.30.1.188   HD-2' >> /etc/hosts
echo '172.30.1.232   HD-3' >> /etc/hosts
echo '### hadoop hosts  end' >> /etc/hosts
echo '' >> /etc/hosts


sed -i 's/VMPF-HD-0/HD-1/g' etc/hadoop/core-site.xml
sed -i 's/VMPF-HD-1/HD-2/g' etc/hadoop/core-site.xml
sed -i 's/VMPF-HD-2/HD-3/g' etc/hadoop/core-site.xml


sed -i 's/VMPF-HD-0/HD-1/g' etc/hadoop/hdfs-site.xml
sed -i 's/VMPF-HD-1/HD-2/g' etc/hadoop/hdfs-site.xml
sed -i 's/VMPF-HD-2/HD-3/g' etc/hadoop/hdfs-site.xml


sed -i 's/VMPF-HD-0/HD-1/g' etc/hadoop/yarn-site.xml
sed -i 's/VMPF-HD-1/HD-2/g' etc/hadoop/yarn-site.xml
sed -i 's/VMPF-HD-2/HD-3/g' etc/hadoop/yarn-site.xml


sed -i 's/VMPF-HD-0/HD-1/g' etc/hadoop/mapred-site.xml
sed -i 's/VMPF-HD-1/HD-2/g' etc/hadoop/mapred-site.xml
sed -i 's/VMPF-HD-2/HD-3/g' etc/hadoop/mapred-site.xml

mkdir -p /hadoop/dfs
mkdir /hadoop/edits
mkdir /hadoop/nmdata
mkdir /hadoop/storage

#jdk anzhuang
export JAVA_HOME=/usr/java/jdk1.7.0_67
export JRE_HOME=$JAVA_HOME/jre
export HADOOP_HOME=/home/hadoop-2.6.0
export PATH=$JAVA_HOME/bin:$JRE_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

vim etc/hadoop/hadoop-env.sh

	
##zookeeper
mkdir -p /hadoop/storage/zookeeper/
echo '1' > /hadoop/storage/zookeeper/myid


172.30.1.238   HD-1
172.30.1.188   HD-2
172.30.1.232   HD-3


启动HDFS
#在所有DataNode中启动Journal节点，在NameNode中执行(hadoop-lion, ${HADOOP_HOME}/sbin/)
./hadoop-daemons.sh start journalnode

#格式化NameNode，在NameNode节点中执行(hadoop-lion)
hadoop namenode -format

#将hadoop-lion格式化后的name文件拷贝给hadoop-tiger中的namenode
scp -r /home/hadoop/name/* hadoop-tiger:/home/hadoop/name/

#在zookeeper中格式化：
hdfs zkfc -formatZK

#在hadoop-rabbit中使用${ZOOKEEPER_HOME}/bin/zkCli.sh验证：ls /
WatchedEvent state:SyncConnected type:None path:null
[zk: localhost:2181(CONNECTED) 0] ls /
[zookeeper, hadoop-ha]

#启动hdfs，在NodeNode节点中执行(hadoop-lion, ${HADOOP_HOME}/sbin/)
./start-dfs.sh

#启动yarn，在ResourceManager节点中执行(hadoop-eagle)
${HADOOP_HOME}/sbin/start-yarn.sh


scp -r dfs/*  root@172.21.2.212:/hddata/dfs/
scp -r edits/namenode  root@172.21.2.212:/hddata/edits/