# -*- coding: UTF-8 -*- 
import os
import sys
import string

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
print("start clean!")

for name in pid_file_list:
    excuteCMD("rm -f " + name)

log_file_list = []
listdir(os.path.join(os.getcwd(), "logs"), log_file_list, '.log')

for name in log_file_list:
    excuteCMD("rm -f logs/" + name)

print("excute over! ")