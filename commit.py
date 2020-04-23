# -*- coding: UTF-8 -*- 
import os
import sys
import string
import time

def excuteCMD(cmd):
	print("excute: " + cmd)
	os.system(cmd)
excuteCMD("git status")
time.sleep(3)
excuteCMD("git add *")
time.sleep(3)
excuteCMD("git commit -m \"commit by script!\"")
time.sleep(3)
excuteCMD("git push origin master")
time.sleep(3)
