local layoututil = require("chatroomeffect.layoututil")

local logic = {}

logic.type = "table"
logic.priority = 100

logic.measure_minsize = function(layout, size, meta, data)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	local sizedtable = table_layout(meta, size)

	local minsize = {
		width = 0,
		height = 0
	}
	for _, rowheight in ipairs(sizedtable.rows) do minsize.height = minsize.height + rowheight end
	for _, columnwidth in ipairs(sizedtable.columns) do minsize.width = minsize.width + columnwidth end

	return minsize
end

logic.do_layout = function(layout, rect, meta, data, callback)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	result = {
		layouttype = "table",
		rect = {
			x = nil,
			y = nil,
			width = size.width,
			height = size.height
		}
	}

	for _, content in ipairs(meta.layouts) do
		-- �����Ӳ��ֵĿ��÷�Χ��
		local contentavaliablerect = {
			x = rect.x,
			y = rect.y,
			width = 0,
			height = 0
		}
		for r = 1, content.row + content.rowspan - 1 do
			if r < content.row then
				contentavaliablerect.y = contentavaliablerect.y + sizedtable.rows[r]
			else
				contentavaliablerect.height = contentavaliablerect.height + sizedtable.rows[r]
			end
		end
		for c = 1, content.column + content.columnspan - 1 do
			if c < content.column then
				contentavaliablerect.x = contentavaliablerect.x + sizedtable.columns[c]
			else
				contentavaliablerect.width = contentavaliablerect.width + sizedtable.columns[c]
			end
		end

		-- ���Ӳ��ֽ��в��֡�
		local contentresult = layoututil.do_layout(content.layout, meta.layer, contentavaliablerect, data)

		table.insert(result, contentresult)
	end

	return result
end

local parse_meta = function(layout, size, data, meta)
	meta = util.copy(meta or {})

	-- �ռ����������Ӳ��ֵ���Ϣ��
	meta.layouts = {}
	for _i, content in ipairs(layout) do
		local row, column, rowspan, columnspan
		row = tonumber(content["table$row"]) or 1
		if row < 1 then error("rowӦ����0��") end
		column = tonumber(content["table$column"]) or 1
		if row < 1 then error("columnӦ����0��") end
		rowspan = tonumber(content["table$rowspan"]) or 1
		if row < 1 then error("rowspanӦ����0��") end
		columnspan = tonumber(content["table$columnspan"]) or 1
		if row < 1 then error("columnspanӦ����0��") end
		
		table.insert(meta.layouts, {
			row = row,
			column = column,
			rowspan = rowspan,
			columnspan = columnspan,
			layout = content
		})
	end

	-- ���������иߡ�
	-- ��ʽ������иߡ�
	if layout.rows == nil then meta.rows = {}
	elseif type(layout.rows) == "string" then
		if util.trim(layout.rows) == "" then
			meta.rows = {}
		elseif regexutil.find("^\\s*(auto|(\\d*\\.\\d*|\\d+)\\*?)?(\\s*,\\s*(auto|(\\d*\\.\\d*|\\d+)\\*?)*\\s*$", layout.rows) then
			meta.rows = {}
			regexresult = regexutil.find("(?:(^|,)\\s*)(auto|(\\d*\\.\\d*|\\d+)\\*?)(?:\\s*($|,))", layout.margin)
			for _, match in ipairs(regexresult) do
				local f, rowheight = tablelength_parse(row)
				if f then table.insert(meta.rows, rowheight)
				else log_error("rowsֵ�ĸ�ʽ����ȷ��")
				end
			end
		else log_error("rowsֵ�ĸ�ʽ����ȷ��")
		end
	elseif type(layout.rows) == "table" then
		meta.rows = {}
		for _, row in layout.rows do
			local f, rowheight = tablelength_parse(row)
			if f then table.insert(meta.rows, rowheight)
			else log_error("rowsֵ�ĸ�ʽ����ȷ��")
			end
		end
	else log_error("rowsֵ�ĸ�ʽ����ȷ��")
	end
	-- ��ʽ������иߡ�
	for _, l in ipairs(meta.layouts) do
		for i = 1, l.row + l.rowspan - 1 do
			if meta.rows[i] == nil then
				_, meta.rows[i] = tablelength_parse(nil)
			end
		end
	end

	-- ���������п�
	-- ��ʽ������п�
	if layout.columns == nil then meta.columns = {}
	elseif type(layout.columns) == "string" then
		if util.trim(layout.columns) == "" then
			meta.columns = {}
		elseif regexutil.find("^\\s*(auto|(\\d*\\.\\d*|\\d+)\\*?)?(\\s*,\\s*(auto|(\\d*\\.\\d*|\\d+)\\*?)*\\s*$", layout.columns) then
			meta.columns = {}
			regexresult = regexutil.find("(?:(^|,)\\s*)(auto|(\\d*\\.\\d*|\\d+)\\*?)(?:\\s*($|,))", layout.margin)
			for _, match in ipairs(regexresult) do
				local f, columnheight = tablelength_parse(column)
				if f then table.insert(meta.columns, columnheight)
				else log_error("columnsֵ�ĸ�ʽ����ȷ��")
				end
			end
		else log_error("columnsֵ�ĸ�ʽ����ȷ��")
		end
	elseif type(layout.columns) == "table" then
		meta.columns = {}
		for _, column in layout.columns do
			local f, columnheight = tablelength_parse(column)
			if f then table.insert(meta.columns, columnheight)
			else log_error("columnsֵ�ĸ�ʽ����ȷ��")
			end
		end
	else log_error("columnsֵ�ĸ�ʽ����ȷ��")
	end
	-- ��ʽ������п�
	for _, l in ipairs(meta.layouts) do
		for i = 1, l.column + l.columnspan - 1 do
			if meta.columns[i] == nil then
				_, meta.columns[i] = tablelength_parse(nil)
			end
		end
	end
	
	return meta
end

local tablelength_parse = function(length)
	if length == nil then
		return true, { type = "weight", value = 1 }
	elseif tonumber(length) ~= nil then
		return true, { type = "pixel", value = tonumber(length) }
	elseif type(length) == "string" then
		if unicode.to_lower_case(length) == "auto" then
			return true, { type = "auto" }
		elseif regexutil.find("^\\s*(\\d*\\.\\d*|\\d+)\\s*\\*\\s*$", length) then
			return true, { type = "weight", value = tonumber(regexutil.match("\\d*\\.\\d*|\\d+", length)[1].str) }
		end
	elseif type(length) == "table" then
		if type(length.type) == "string" then
			if unicode.to_lower_case(length.type) == "auto" then
				return true, { type = "auto" }
			elseif unicode.to_lower_case(length.type) == "pixel" and tonumber(length.value) ~= nil then
				return true, { type = "pixel", value = tonumber(length.value) }
			elseif unicode.to_lower_case(length.type) == "weight" and tonumber(length.value) ~= nil then
				if tonumber(length.value) == 0 then return true, { type = "pixel", value = 0 }
				else return true, { type = "weight", value = tonumber(length.value) }
				end
			end
		end
	end
			
	return false
end

--[[ ���б�ʽ���֡�
---- ������ meta, size, text
	meta: ���Ͳ��ֵõ���Ԫ���ݡ�
	size: ���ڲ��ֵ�Ԥ����Χ��
---- ���أ� tablelengthinfo
	sizedtable: ȷ�����������еĸ߶Ⱥ��еĿ�ȡ�
--]]
local table_layout = function(meta, size)
	local layouttable = {}
	local sizedtable = { rows = {}, columns = {} }

	for _, content in meta.layouts do
		-- ���иߺ��п����Ϊ���ء��Զ���Ȩ�����ࡣ
		local rowpixels, columnpixels = { total = 0 }, { total = 0 }
		local rowautos, columnautos = { total = 0 }, { total = 0 }
		local rowweights, columnweights = { total = 0 }, { total = 0 }

		for r = content.row, content.row + content.rowspan - 1 do
			local row = meta.rows[r]
			if row.type == "pixel" then
				table.insert(rowpixels, { row = r, value = row.value })
				rowpixels.total = rowpixels.total + row.value
			elseif row.type == "auto" then
				table.insert(rowautos, r)
				rowautos.total = rowautos.total + 1
			elseif row.type == "weight" then
				table.insert(rowweights, { row = r, value = row.value })
				rowweights.total = rowweights.total + row.value
			end
		end
		for c = content.column, content.column + content.columnspan - 1 do
			local column = meta.columns[c]
			if column.type == "pixel" then
				table.insert(columnpixels, { column = c, value = column.value })
				columnpixels.total = columnpixels.total + column.value
			elseif column.type == "auto" then
				table.insert(columnautos, c)
				columnautos.total = columnautos.total + 1
			elseif column.type == "weight" then
				table.insert(columnweights, { column = c, value = column.value })
				columnweights.total = columnweights.total + column.value
			end
		end

		-- ������÷�Χ�ߴ硣
		local contentavaliablerectsize = {
			width = nil,
			height = nil
		}
		if #rowautos == 0 and #rowweights == 0 then contentavaliablerectsize.height = rowpixels end
		if #columnautos == 0 and #columnweights == 0 then contentavaliablerectsize.width = columnpixels end

		-- ������С�ߴ硣
		contentminsize = layoututil.measure_minsize(content.layout, contentavaliablerectsize, data)
		-- ����С�ߴ籣����content��������������ʱ�Ĳο���
		content.minsize = contentminsize
		
		--[[
			ʹ��ÿ���Ӳ��ֵ���С�ߴ���иߺ��п���з��䣬���ȡ���з���ֵ�����ֵ��
			��ÿ�η����ֵ�������б��У��Ա��������
		--]]

		-- ʹ����С�ߴ���и߽��г������䣬��Ҫ��Զ����Ԫ��ϲ���Ĵ�Ԫ��
		if #rowpixels ~= 0 then for _, ri in ipairs(rowpixels) do sizedtable.rows[ri.row] = ri.value end end
		if contentminsize.height > rowpixels.total then
			local rl = contentminsize.height - rowpixels.total
			if #rowweights ~= 0 then
				for _, ri in ipairs(rowweights) do
					if sizedtable.rows[ri.row] == nil then sizedtable.rows[ri.row] = {} end
					table.insert(sizedtable.rows[ri.row], rl / rowweights.total * ri.value)
				end
			elseif #rowautos ~= 0 then
				for _, ri in ipairs(rowautos) do
					if sizedtable.rows[ri.row] == nil then sizedtable.rows[ri.row] = {} end
					table.insert(sizedtable.rows[ri.row], rl / #rowautos)
				end
			end
		end
		
		-- ʹ����С�ߴ���п���г������䣬��Ҫ��Զ����Ԫ��ϲ���Ĵ�Ԫ��
		if #columnpixels ~= 0 then for _, ci in ipairs(columnpixels) do sizedtable.rows[ci.column] = ci.value end end
		if contentminsize.height > columnpixels.total then
			local cl = contentminsize.height - columnpixels.total
			if #columnweights ~= 0 then
				for _, ci in ipairs(columnweights) do
					if sizedtable.columns[ci.column] == nil then sizedtable.columns[ci.column] = {} end
					table.insert(sizedtable.columns[ci.column], cl / columnweights.total * ci.value)
				end
			elseif #columnautos ~= 0 then
				for _, ci in ipairs(columnautos) do
					if sizedtable.columns[ci.column] == nil then sizedtable.columns[ci.column] = {} end
					table.insert(sizedtable.columns[ci.column], cl / #columnautos)
				end
			end
		end
	end

	-- ���������иߵķ���ֵ�����ֵ��
	for r, rh in ipairs(sizedtable.rows) do
		if type(rh) == "table" then -- ��һ����������ֵ��
			if #rh <= 1 then sizedtable[r] = nil
			else
				local max = 0
				for _, rhv in ipairs(rh) do max = math.max(max, rhv) end
				sizedtable[r] = max
			end
		end
	end
	-- ���������п�ķ���ֵ�����ֵ��
	for c, ch in ipairs(sizedtable.columns) do
		if type(ch) == "table" then -- ��һ����������ֵ��
			if #ch <= 1 then sizedtable[c] = nil
			else
				local max = 0
				for _, rhv in ipairs(ch) do max = math.max(max, rhv) end
				sizedtable[c] = max
			end
		end
	end
	
	--[[
		��ʱ�Կ��ܴ���ֵΪnil���иߺ��п�nil��ʾ����ֵΪ0���Զ���Ȩ�����͵ķ���ֵ����һ����Ӧ���¼������Ż���
	--]]

	-- ���¼���ֵΪnil���иߺ��п�
	for _, content in meta.layouts do
		-- ���иߺ��п����Ϊ���ء��Զ���Ȩ�����ࡣ
		local rowpixels, columnpixels = 0, 0
		local rowautos, columnautos = { total = 0 }, { total = 0 }
		local rowweights, columnweights = { total = 0 }, { total = 0 }

		for r = content.row, content.row + content.rowspan - 1 do
			if sizedtable.rows[r] == nil then
				local row = meta.columns[r]
				if row.type == "auto" then
					table.insert(rowautos, r)
					rowautos.total = rowautos.total + 1
				elseif row.type == "weight" then
					table.insert(rowweights, { row = r, value = row.value })
					rowweights.total = rowweights.total + row.value
				end
			else
				rowpixels = rowpixels + sizedtable.rows[r]
			end
		end
		for c = content.column, content.column + content.columnspan - 1 do
			if sizedtable.columns[c] == nil then
				local column = meta.columns[c]
				if column.type == "auto" then
					table.insert(columnautos, c)
					columnautos.total = columnautos.total + 1
				elseif column.type == "weight" then
					table.insert(columnweights, { column = c, value = column.value })
					columnweights.total = columnweights.total + column.value
				end
			else
				columnpixels = columnpixels + sizedtable.columns[c]
			end
		end

		-- ʹ����С�ߴ���и߽����ٴη��䣬��Ҫ��Զ����Ԫ��ϲ���Ĵ�Ԫ��
		if content.minsize.height > rowpixels then
			local rl = content.minsize.height - rowpixels
			if #rowweights ~= 0 then
				for _, ri in ipairs(rowweights) do
					sizedtable.rows[ri.row] = rl / rowweights.total * ri.value
				end
			elseif #rowautos ~= 0 then
				for _, ri in ipairs(rowautos) do
					sizedtable.rows[ri.row] = rl / #rowautos
				end
			end
		end
		
		-- ʹ����С�ߴ���п�����ٴη��䣬��Ҫ��Զ����Ԫ��ϲ���Ĵ�Ԫ��
		if content.minsize.height > columnpixels then
			local cl = content.minsize.height - columnpixels
			if #columnweights ~= 0 then
				for _, ci in ipairs(columnweights) do
					sizedtable.columns[ci.column] = cl / columnweights * ci.value
				end
			elseif #columnautos ~= 0 then
				for _, ci in ipairs(columnautos) do
					sizedtable.columns[ci.column] = cl / #columnautos
				end
			end
		end
	end
	
	--[[
		��ʱ�Կ��ܴ���ֵΪnil���иߺ��п�nil��ʾ����ֵΪ0��
	--]]

	for r, rh in ipairs(sizedtable.rows) do if rh == nil then sizedtable.rows[r] = 0 end end
	for c, ch in ipairs(sizedtable.columns) do if ch == nil then sizedtable.columns[c] = 0 end end

	-- �ռ�����Ȩ�����͵��иߺ��п�
	local rowpixels, columnpixels = 0, 0
	local rowweights, columnweights = { total = 0 }, { total = 0 }
	for r, row in ipairs[meta.rows] do
		if row.type == "weight" then
			table.insert(rowweights, { row = r, value = row.value, length = sizedtable.rows[r] })
			rowweights.total = rowweights.total + row.value
		else
			rowpixels = rowpixels + sizedtable.rows[r]
		end
	end
	for c, column in ipairs[meta.columns] do
		if column.type == "weight" then
			table.insert(columnweights, { column = c, value = column.value, length = sizedtable.columns[c] })
			columnweights.total = columnweights.total + column.value
		else
			columnpixels = columnpixels + sizedtable.columns[c]
		end
	end

	-- ����Ȩ�ض��иߺ��п�������շ��䡣
	if size.width == nil then -- �Զ����
		-- ������������ֵ��
		local scale = 0
		for c, cw in ipairs(columnweights) do scale = math.max(scale, cw.length / cw.value) end
		-- ����Ȩ�غͱ��������п�
		for c, cw in ipairs(columnweights) do sizedtable.columns[c] = scale * cw.value end
	else -- ָ�����
		-- ����Ȩ�����п��ܺ͡�
		local length = math.max(0, size.width - columnpixels)
		-- ����Ȩ�غ�Ȩ���ܺͼ����п�
		for c, cw in ipairs(columnweights) do sizedtable.columns[c] = length / columnweights.total * cw.value end
	end
	if size.width == nil then -- �Զ��߶�
		-- ������������ֵ��
		local scale = 0
		for r, rw in ipairs(rowweights) do scale = math.max(scale, rw.length / rw.value) end
		-- ����Ȩ�غͱ��������иߡ�
		for r, rw in ipairs(rowweights) do sizedtable.rows[r] = scale * rw.value end
	else -- ָ���߶�
		-- ����Ȩ�����и��ܺ͡�
		local length = math.max(0, size.width - rowpixels)
		-- ����Ȩ�غ�Ȩ���ܺͼ����иߡ�
		for r, rw in ipairs(rowweights) do sizedtable.rows[r] = length / rowweights.total * rw.value end
	end

	return sizedtable
end