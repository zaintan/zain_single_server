# -*- coding: UTF-8 -*- 
import os
import sys
import string


def excuteCMD(cmd):
	print("excute: " + cmd)
	os.system(cmd)
##run new
excuteCMD("sh server_alloc/start.sh 301")
excuteCMD("sh server_login/start.sh 201")
excuteCMD("sh server_game/start.sh 401")
excuteCMD("sh server_agent/start.sh 101")
print("excute over! ")