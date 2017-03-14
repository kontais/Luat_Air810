module(...,package.seeall)

--[[
ģ�����ƣ���������
ģ�鹦�ܣ�������ʼ������д�Լ��ָ���������
ģ������޸�ʱ�䣺2017.02.23
]]


package.path = "/?.lua;".."/?.luae;"..package.path

--[[
configname: �洢Ĭ�ϲ������õ��ļ�
econfigname�� �洢Ĭ�ϲ������õļ����ļ�
paraname: �洢ʵʱ�������õ��ļ�
para��ʵʱ������
]]
local configname,econfigname,paraname,para = "/lua/config.lua","/lua/config.luae","/para.lua"
local ssub,sgsub = string.sub,string.gsub

--[[
��������print
����  ����ӡ�ӿڣ����ļ��е����д�ӡ�������nvmǰ׺
����  ����
����ֵ����
]]
local function print(...)
	_G.print("nvm",...)
end

--[[
��������restore
����  �������ָ��������ã���configname�ļ������ݸ��Ƶ�paraname�ļ���
����  ����
����ֵ����
]]
function restore()
	local fpara,fconfig = io.open(paraname,"wb"),io.open(configname,"rb")
	if not fconfig then fconfig = io.open(econfigname,"rb") end
	fpara:write(fconfig:read("*a"))
	fpara:close()
	fconfig:close()
	para = config
end

--[[
��������serialize
����  �����ݲ�ͬ���������ͣ����ղ�ͬ�ĸ�ʽ��д��ʽ��������ݵ��ļ���
����  ��
		pout���ļ����
		o������
����ֵ����
]]
local function serialize(pout,o)
	if type(o) == "number" then
		--number���ͣ�ֱ��дԭʼ����
		pout:write(o)
	elseif type(o) == "string" then
		--string���ͣ�ԭʼ�������Ҹ�����˫����д��
		pout:write(string.format("%q", o))
	elseif type(o) == "boolean" then
		--boolean���ͣ�ת��Ϊstringд��
		pout:write(tostring(o))
	elseif type(o) == "table" then
		--table���ͣ��ӻ��У������ţ������ţ�˫����д��
		pout:write("{\n")
		for k,v in pairs(o) do
			if type(k) == "number" then
				pout:write(" [", k, "] = ")
			elseif type(k) == "string" then
				pout:write(" [\"", k,"\"] = ")
			else
				error("cannot serialize table key " .. type(o))
			end
			serialize(pout,v)
			pout:write(",\n")
		end
		pout:write("}\n")
	else
		error("cannot serialize a " .. type(o))
	end
end

--[[
��������upd
����  ������ʵʱ������
����  ����
����ֵ����
]]
local function upd()
	for k,v in pairs(config) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			if para[k] == nil then
				para[k] = v
			end			
		end
	end
end

--[[
��������load
����  ����ʼ������
����  ����
����ֵ����
]]
local function load()
	local f = io.open(paraname,"rb")
	if not f or f:read("*a") == "" then
		if f then f:close() end
		restore()
		return
	end
	f:close()
	
	f,para = pcall(require,string.match(paraname,"/(.+)%.lua"))
	if not f then
		restore()
		return
	end
	upd()
end

--[[
��������save
����  ����������ļ�
����  ��
		s���Ƿ��������棬true���棬false����nil������
����ֵ����
]]
local function save(s,flu)
	if not s then return end
	local f = io.open(paraname,"wb")

	f:write("module(...)\n")

	for k,v in pairs(para) do
		if k ~= "_M" and k ~= "_NAME" and k ~= "_PACKAGE" then
			f:write(k, " = ")
			serialize(f,v)
			f:write("\n")
		end
	end

	if flu then f:flush() end
	f:close()
end

--[[
��������set
����  ������ĳ��������ֵ
����  ��
		k��������
		v����Ҫ���õ���ֵ
		r������ԭ��ֻ�д�������Ч����������v����ֵ�;�ֵ�����˸ı䣬�Ż��׳�PARA_CHANGED_IND��Ϣ
		s���Ƿ���Ҫд�뵽�ļ�ϵͳ�У�false��д�룬����Ķ�д��
����ֵ��true
]]
function set(k,v,r,s)
	local bchg = true
	if type(v) == "table" then
		for kk,vv in pairs(para[k]) do
			if vv ~= v[kk] then bchg = true break end
		end
	else
		bchg = (para[k] ~= v)
	end
	print("set",bchg,k,v,r,s)
	if bchg then		
		para[k] = v
		save(s or s==nil)
	end
	if r then sys.dispatch("PARA_"..(bchg and "CHANGED" or "SET").."_IND",k,v,r) end
	return true
end

--[[
��������sett
����  ������table���͵Ĳ����е�ĳһ���ֵ
����  ��
		k��table������
		kk��table�����еļ�ֵ
		v����Ҫ���õ���ֵ
		r������ԭ��ֻ�д�������Ч����������v����ֵ�;�ֵ�����˸ı䣬�Ż��׳�TPARA_CHANGED_IND��Ϣ
		s���Ƿ���Ҫд�뵽�ļ�ϵͳ�У�false��д�룬����Ķ�д��
����ֵ��true
]]
function sett(k,kk,v,r,s)
	print("sett",k)
	--if para[k][kk] ~= v then
		para[k][kk] = v
		save(s or s==nil)
		if r then sys.dispatch("TPARA_CHANGED_IND",k,kk,v,r) end
	--end
	return true
end

--[[
��������flush
����  ���Ѳ������ڴ�д���ļ���
����  ����
����ֵ����
]]
function flush(s)
	save(true,s)
end

--[[
��������get
����  ����ȡ����ֵ
����  ��
		k��������
����ֵ������ֵ
]]
function get(k)
	if type(para[k]) == "table" then
		local tmp = {}
		for kk,v in pairs(para[k]) do
			tmp[kk] = v
		end
		return tmp
	else
		return para[k]
	end
end

--[[
��������gett
����  ����ȡtable���͵Ĳ����е�ĳһ���ֵ
����  ��
		k��table������
		kk��table�����еļ�ֵ
����ֵ������ֵ
]]
function gett(k,kk)
	return para[k][kk]
end

--[[
��������init
����  ����ʼ�������洢ģ��
����  ��
		dftcfgfile��Ĭ�������ļ�
����ֵ����
]]
function init(dftcfgfile)
	pcall(require,string.match(dftcfgfile,"(.+)%.lua"))
	configname,econfigname = "/lua/"..dftcfgfile,"/lua/"..dftcfgfile.."e"
	--��ʼ�������ļ������ļ��аѲ�����ȡ���ڴ���
	load()
end