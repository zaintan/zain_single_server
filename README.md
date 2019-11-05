# zain_single_server

git clone https://github.com/zaintan/zain_single_server.git
git submodule init
git submodule update

cd zain_single_server
git submodule add https://github.com/zaintan/skynet skynet
git submodule add https://github.com/zaintan/pbc pbc

##配置
git config --global user.email "tzytclzxh@qq.com"
git config --global user.name "zain_win"

##提交
git add *
git commit -m "log"
git push origin master

##拉取
git pull origin

编译skynet
cd skynet;make clean;make linux;

##编译pbc
cd pbc;make clean;make;

##编译protobuf.so
缺少protobuf.so,在pbc/binding/lua53目录下 make clean; make;如果缺少lua环境,修改Makefile文件 LUADIR = ./../../../skynet/3rd/lua

cd pbc/binding/lua53;make clean;make;

cp protobuf.so ./../../../skynet/luaclib/
cp protobuf.lua ./../../../skynet/lualib/


#!/bin/bash
dos2unix servers/server_single/start.sh

--to do:
胡牌还未考虑 按位置先后的优先级  一炮多响的情况


-----------------------------------------------------------
//aliyun oss  install faqs---------------------------------
yum install git

error 1:
./autogen.sh: line 5: autoconf: command not found
yum install install autoconf automake libtool

error 2:
lua.c:83:31: fatal error: readline/readline.h: No such file or directory
缺少libreadline-dev依赖包
centos: yum install readline-devel

error 3:
make: protoc: Command not found
make: *** [build/addressbook.pb] Error 127

// https://github.com/protocolbuffers/protobuf/releases/tag/v2.5.0
// 下载 protobuf-2.5.0.zip
wget https://github.com/protocolbuffers/protobuf/releases/download/v2.5.0/protobuf-2.5.0.zip

yum install unzip 
unzip protobuf-2.5.0.zip

yum install glibc-headers
yum install gcc-c++

./configure
make
make install

1.
a)下载mysql源安装包:wget http://dev.mysql.com/get/mysql57-community-release-el7-8.noarch.rpm
b)安装mysql源:yum localinstall mysql57-community-release-el7-8.noarch.rpm
若结尾出现complete!，则说明MySQL源安装完成

c)检测是否安装完成:yum repolist enabled | grep "mysql.*-community.*"
d)安装mysql:yum install mysql-community-server
若结尾出现Complete!， 则MySQL安装完成

e)设置开启启动mysql服务:systemctl enable mysqld

f)查看安装的mysql版本:rpm -aq | grep -i mysql
g)启动MySQL服务：systemctl restart mysqld
h)查看MySQL初始密码：grep 'A temporary password' /var/log/mysqld.log
i)更改MySQL密码：mysqladmin -u root -p'旧密码' password '新密码'
j)设置mysql能够远程访问:
	登录进MySQL：mysql -u root -p Tzy0930!
	增加一个用户给予访问权限：grant all privileges on *.* to '用户名'@'ip地址' identified by '密码' with grant option; //可将ip改为%%,表示开启所有的