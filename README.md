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


