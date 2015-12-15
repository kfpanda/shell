#!/bin/bash

#传入参数 文件名
#返回值   0,合法;其他值非法或出错
function check_syntax()
{
	if [ ! -f $1 ];then 
		return 1
	fi

	ret=$(awk -F= 'BEGIN{valid=1}
	{
		#已经找到非法行,则一直略过处理
		if(valid == 0) next
		#忽略空行	
		if(length($0) == 0) next
		#消除所有的空格
		gsub(" |\t","",$0)	
		#检测是否是注释行	
		head_char=substr($0,1,1)
		if (head_char != "#"){
			#不是字段=值 形式的检测是否是块名
			if( NF == 1){
				b=substr($0,1,1)
				len=length($0)
				e=substr($0,len,1)
				if (b != "[" || e != "]"){
					valid=0
				}
			}else if( NF == 2){
			#检测字段=值 的字段开头是否是[
				b=substr($0,1,1)
				if (b == "["){
					valid=0
				}
			}else{
			#存在多个=号分割的都非法
				valid=0
			}	
		}
	}
	END{print valid}' $1)
	
	if [ $ret -eq 1 ];then
		return 0
	else
		return 2
	fi
}

#参数1 文件名
#参数2 块名
#参数3 字段名
#返回0,表示正确,且能输出字符串表示找到对应字段的值
#否则其他情况都表示未找到对应的字段或者是出错
function get_field_value()
{
	if [ ! -f $1 ] || [ $# -ne 3 ];then
		return 1
	fi
	blockname=$2
	fieldname=$3

	begin_block=0
	end_block=0

	cat $1 | while read line
	do
	
		if [ "X$line" = "X[$blockname]" ];then
			begin_block=1
			continue
		fi
		
		if [ $begin_block -eq 1 ];then
			end_block=$(echo $line | awk 'BEGIN{ret=0} /^\[.*\]$/{ret=1} END{print ret}')
			if [ $end_block -eq 1 ];then
				#echo "end block"
				break
			fi
	
			need_ignore=$(echo $line | awk 'BEGIN{ret=0} /^#/{ret=1} /^$/{ret=1} END{print ret}')
			if [ $need_ignore -eq 1 ];then
				#echo "ignored line:" $line
				continue
			fi
			field=$(echo $line | awk -F= '{gsub(" |\t","",$1); print $1}')
			value=$(echo $line | awk -F= '{gsub(" |\t","",$2); print $2}')
			#echo "'$field':'$value'"
			if [ "X$fieldname" = "X$field" ];then	
				#echo "result value:'$result'"
				echo $value
				break
			fi
			
		fi
	done
	return 0
}
