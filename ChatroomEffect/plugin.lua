unicode = require("aegisub.unicode")
regexutil = require("aegisub.re")
util = require("aegisub.util")
lfs = require("lfs")
require("chatroomeffect.util")

local layoutsdir = "automation\\include\\chatroomeffect\\layouts"
local layoutsrequirepath = "chatroomeffect.layouts"

local plugin = {}

plugin.layouts = {}
for entry in lfs.dir(layoutsdir)
	if entry~='.' and entry~='..' then
		local path = layoutsdir.."\\"..entry
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
						if plugin.layouts[layoutdef.type] == nil then
							plugin.layouts[layoutdef.type] = layoutdef
						elseif plugin.layouts[layoutdef.type].priority == layoutdef.priority then
							error("������ȼ���һ�£�������ͻ��")
						elseif plugin.layouts[layoutdef.type].priority < layoutdef.priority then
							plugin.layouts[layoutdef.type] = layoutdef
						end
					end
					xpcall(loadlayoutdef, function(err)
						log_warning(string.format("���ز��ֲ��ʧ�ܣ�%s\n%s", err, debug.traceback()))
					end)
				end
			end
		end
	end
end

return plugin