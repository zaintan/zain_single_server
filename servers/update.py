# -*- coding: UTF-8 -*- 
import os
import sys
import string

def excuteCMD(cmd):
	print("excute: " + cmd)
	os.system(cmd)

excuteCMD("python clean.py")
excuteCMD("git checkout .")
excuteCMD("git pull origin master")
excuteCMD("python makeproto.py")
excuteCMD("python start.py")
