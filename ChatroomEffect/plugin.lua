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
				local loadlayoutlogic = function()
					local layoutlogic = require(layoutsrequirepath.."."..filename) -- ���ز��ֲ����
					local loadinternal = function(layoutlogictype, layoutlogic)
						if plugin.logics[layoutlogictype] == nil then
							plugin.logics[layoutlogictype] = layoutlogic
						elseif plugin.logics[layoutlogictype] ~= layoutlogic then
							if plugin.logics[layoutlogictype].priority == layoutlogic.priority then
								error("������ȼ����ͻ��")
							elseif plugin.logics[layoutlogictype].priority < layoutlogic.priority then
								plugin.logics[layoutlogictype] = layoutlogic
							end
						end
					end
					if type(layoutlogic.type) == "table" then
						for _, layoutlogictype in ipairs(layoutlogic.type) do
							loadinternal(layoutlogictype, layoutlogic)
						end
					elseif type(layoutlogic.type) == "string" then
						loadinternal(layoutlogic.type, layoutlogic)
					else error("�޷�ʶ�𲼾ֲ�������͡�")
					end
				end
				xpcall(loadlayoutlogic, function(err)
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

local shapesdir = "automation\\include\\chatroomeffect\\shapes"
local shapesrequirepath = "chatroomeffect.shapes"
plugin.shapes = {}
plugin.loadlayoutshape = function(path)
	local attr = lfs.attributes(path)
	assert(type(attr) == "table") -- �����ȡ�������Ա��򱨴�
	
	if attr.mode == "file" then
		local regexresult = regexutil.match(".*([^\\\\\\/\\.]+)(\\.[^\\\\\\/\\.]+)", path)
		if regexresult then
			local filename, fileextension = regexresult[2].str, regexresult[3].str
			if unicode.to_lower_case(fileextension) == ".lua" or unicode.to_lower_case(fileextension) == ".dll" then
				local loadshape = function()
					local shape = require(layoutsrequirepath.."."..filename) -- ������״�����
					if type(shape.type) ~= string then
						error("�޷�ʶ����״��������͡�")
					end
					if plugin.shapes[shape.type] == nil then
						plugin.shapes[shape.type] = shape
					elseif plugin.shapes[shape.type].priority == shape.priority then
						error("������ȼ����ͻ��")
					elseif plugin.shapes[shape.type].priority < shape.priority then
						plugin.shapes[shape.type] = shape
					end
				end
				xpcall(loadshape, function(err)
					log_warning(string.format("������״���ʧ�ܣ�%s\n%s", err, debug.traceback()))
				end)
			end
		end
	end
end
for entry in lfs.dir(layoutsdir)
	if entry ~= '.' and entry ~= '..' then
		local path = layoutsdir.."\\"..entry
		plugin.loadlayoutshape(path)
	end
end

return plugin