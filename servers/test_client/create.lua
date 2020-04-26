if not _P then
	print "inject create error!"
	return
end 

print("-------_P:")
for k,v in pairs(_P or {}) do
	print(tostring(k),tostring(v))
end

print("-------_P.lua:")
for k,v in pairs(_P.lua or {}) do
	print(tostring(k),tostring(v))
end

print("-------_P.testg:")
print("-------_P.testg:",tostring(_P.testg))

print("-------_P.testgTbl:")
for k,v in pairs(_P.testgTbl or {}) do
	print(tostring(k),tostring(v))
end
--local info = _P.lua.info
--_P.lua.send_create()
--skynet.sleep(200)
--print(info.room_id)
print "inject ok!"