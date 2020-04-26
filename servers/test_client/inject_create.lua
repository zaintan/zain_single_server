if not _P then
	print "inject create error!"
	return
end 

local info = _P.lua.info

_P.lua.send_create()
skynet.sleep(200)

print(info.room_id)
print "inject ok!"