local unicode = require("aegisub.unicode")
local regexutil = require("aegisub.re")
local util = require("aegisub.util")
local lfs = require("lfs")
require("chatroomeffect.util")

local plugin = {}

local layoutsdir = "automation\\include\\chatroomeffect\\layouts"
local layoutsrequirepath = "chatroomeffect.layouts"


local logicsdir = "automation\\include\\chatroomeffect\\logics"
local logicsrequirepath = "chatroomeffect.logics"
plugin.logics = {}
plugin.loadlayoutlogic = function(path)
	local attr = lfs.attributes(path)
	assert(type(attr) == "table") -- �����ȡ�������Ա��򱨴�
	
	if attr.mode == "file" then
		local regexresult = regexutil.match(".*([^\\\\\\/\\.]+)(\\.[^\\\\\\/\\.]+)", path)
		if regexresult then
			local filename, fileextension = regexresult[2].str, regexresult[3].str
			if unicode.to_lower_case(fileextension) == ".lua" or unicode.to_lower_case(fileextension) == ".dll" then
				local loadlayoutdef = function()
					local layoutdef = require(layoutsrequirepath.."."..filename) -- ���ز��ֲ����
					if type(layoutdef.type) ~= string then
						error("�޷�ʶ�𲼾ֲ�������͡�")
					end
					if plugin.logics[layoutdef.type] == nil then
						plugin.logics[layoutdef.type] = layoutdef
					elseif plugin.logics[layoutdef.type].priority == layoutdef.priority then
						error("������ȼ����ͻ��")
					elseif plugin.logics[layoutdef.type].priority < layoutdef.priority then
						plugin.logics[layoutdef.type] = layoutdef
					end
				end
				xpcall(loadlayoutdef, function(err)
					log_warning(string.format("���ز��ֲ��ʧ�ܣ�%s\n%s", err, debug.traceback()))
				end)
			end
		end
	end
end
for entry in lfs.dir(layoutsdir)
	if entry ~= '.' and entry ~= '..' then
		local path = layoutsdir.."\\"..entry
		plugin.loadlayoutlogic(path)
	end
end

return plugin