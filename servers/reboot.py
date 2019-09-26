# -*- coding: UTF-8 -*- 
import os
import sys
import string

path = os.path.join(os.getcwd(), "proto")

def excuteCMD(cmd):
	print("excute: " + cmd)
	os.system(cmd)

def listdir(path,list_name, key):  # 传入存储的list
    for file in os.listdir(path):
        file_path = os.path.join(path, file)
        if not os.path.isdir(file_path):
        	if file_path.find(key)!=-1:##'.pid'
        		list_name.append(file)
##kill old skynet process
pid_file_list = []
listdir(os.getcwd(), pid_file_list, '.pid')

for name in pid_file_list:
    file = open(name, 'r')
    try:
        pid = file.read()
        print(name, pid)
        cmd = "kill " + pid
        excuteCMD(cmd)
    finally:
        file.close()

##run new
excuteCMD("sh server_alloc/start.sh 301")
excuteCMD("sh server_login/start.sh 201")
excuteCMD("sh server_game/start.sh 401")
excuteCMD("sh server_agent/start.sh 101")
print("excute over! ")