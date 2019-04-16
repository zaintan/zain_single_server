# -*- coding: UTF-8 -*- 
import os
import sys
import string

path = os.path.join(os.getcwd(), "proto")

def excuteCMD(cmd):
	print("excute: " + cmd)
	os.system(cmd)

def listdir(path,list_name):  # 传入存储的list
    for file in os.listdir(path):
        file_path = os.path.join(path, file)
        if not os.path.isdir(file_path):
        	if file_path.find('.proto')!=-1:
        		list_name.append(file)

l = []
listdir(path, l)

for name in l:
    input_name = name.replace(".proto",".pb")
    cmd = "protoc -o ./" + input_name + " ./proto/" + name
    excuteCMD(cmd)
