local logic = {}

logic.type = "text"
logic.priority = 100

logic.measure_minsize = function(layout, size, meta, data)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	-- �����ı����֡�
	local wrappedtextminsize, wrappedtext = text_layout(meta, size)
	
	return wrappedtextminsize
end

logic.do_layout = function(layout, rect, meta, data)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	-- �����ı����֡�
	local wrappedtextminsize, wrappedtext = text_layout(meta, size)
	
	result = {
		layouttype = "text",
		rect = {
			x = nil,
			y = nil,
			width = wrappedtextminsize.width,
			height = wrappedtextminsize.height
		},
		texthorizontalalignment = texthorizontalalignment,
		textverticalalignment = textverticalalignment,
		text = wrappedtext
	}
	
	return result
end

local parse_meta = function(layout, size, data, meta)
	meta = util.copy(meta or {})
	
	-- ��ȡ�ı�ʹ�õ���ʽ��
	meta.style = style_parse(data.styles, layout.style)

	-- �����ı����з�ʽ
	if layout.wordwrap == nil then meta.wordwrap = "none"
	elseif unicode.to_lower_case(layout.wordwrap) == "none" or
		unicode.to_lower_case(layout.wordwrap) == "hard" or
		unicode.to_lower_case(layout.wordwrap) == "soft" then
		meta.wordwrap = unicode.to_lower_case(layout.wordwrap)
	else log_error("wordwrapֵ�ĸ�ʽ����ȷ��")
	end
	
	-- �����ı��ĺ����������롣
	local texthorizontalalignment, textverticalalignment
	if layout.texthorizontalalignment == nil then texthorizontalalignment = "left"
	elseif unicode.to_lower_case(layout.texthorizontalalignment) == "left" or
		unicode.to_lower_case(layout.texthorizontalalignment) == "center" or
		unicode.to_lower_case(layout.texthorizontalalignment) == "right" then
		texthorizontalalignment = unicode.to_lower_case(layout.texthorizontalalignment)
	else log_error("texthorizontalalignmentֵ�ĸ�ʽ����ȷ��")
	end
	if layout.textverticalalignment == nil then textverticalalignment = "left"
	elseif unicode.to_lower_case(layout.textverticalalignment) == "left" or
		unicode.to_lower_case(layout.textverticalalignment) == "center" or
		unicode.to_lower_case(layout.textverticalalignment) == "right" then
		textverticalalignment = unicode.to_lower_case(layout.textverticalalignment)
	else log_error("textverticalalignmentֵ�ĸ�ʽ����ȷ��")
	end
	
	-- ��ȡ�ı���
	if type(layout.text) == string then metatext = layout.text
	else metatext = ""
	end
	
	return meta
end

--[[ �����ı�����
---- ������ meta, size, text
	meta: ���Ͳ��ֵõ���Ԫ���ݡ�
	size: ���ڲ��ֵ�Ԥ����Χ��
	text: ��Ҫ������ı�����Ϊnilʱ��ȡmeta.text��
---- ���أ� minsize, wrappedtext
	 minsize: ���ֺ��ı�ռ�õľ��ε���С��Χ��
	 wrappedtext: ���ֺ���ı���
--]]
local text_layout = function(meta, size, text)
	text = text or meta.text

	local rawlines = regexutil.split(text, "\\r?\\n")
	local linebuffer = { length = 0 }
	for _, rawline in ipairs(rawlines) do
		if rawline == "" then -- ��Ϊ���У���߶�Ϊ��ʽ�������С��һ�롣
			table.insert(linebuffer, rawline)
			linebuffer.height = linebuffer.height + meta.style.fontsize / 2
		else
			if meta.wordwrap == "none" then -- ������
				table.insert(linebuffer, rawline)
				local w, h, d, el = aegisub.text_extents(meta.style, rawline)
				linebuffer.length = math.max(linebuffer.length, w)
				linebuffer.height = linebuffer.height + h
			else
				regexresult = regexutil.match("\\s+(?=\\S|$)|[\\dA-Za-z]+(?=[^\\dA-Za-z]|$)|\\b.+?\\b|\\S+(?=\\s|$)", rawline)
				
				local spanbuffer = {}
				for _, match in ipairs(regexresult) do
					local wrappable
					if meta.wordwrap == "hard" then -- Ӳ����
						wrappable = true -- �����ı��ξ������ֻ��С�
					elseif meta.wordwrap == "soft" then -- ����
						if regexutil.find("^(\\s+|[\\dA-Za-z]+)$", match.str) then wrappable = false -- �����ֺ���ĸ��������ϲ������ֻ��С�
						else wrappable = true -- ������Ͼ������ֻ��С�
						end
					end
					
					table.insert(spanbuffer, match.str)
					while true do
						local w, h, d, el = aegisub.text_extents(meta.style, table.concat(spanbuffer))
						if size.width == nil or w <= size.width then break
						elseif wrappable or #spanbuffer == 1 then
							table.remove(spanbuffer, #spanbuffer)
							
							for c in unicode.chars(match.str) do
								table.insert(spanbuffer, c)
								local w, h, d, el = aegisub.text_extents(meta.style, table.concat(spanbuffer))
								if #spanbuffer > 1 and size.width ~= nil and w > size.width then
									table.remove(spanbuffer, #spanbuffer)
									spanbuffer.length, spanbuffer.height = aegisub.text_extents(style, table.concat(spanbuffer))
									table.insert(linebuffer, table.concat(spanbuffer))
									linebuffer.length = math.max(linebuffer.length, spanbuffer.length)
									linebuffer.height = linebuffer.height + spanbuffer.height
									spanbuffer = {}
									table.insert(spanbuffer, c)
								end
							end
							if #spanbuffer > 1 then
								spanbuffer = { table.concat(spanbuffer) }
							end
						else
							table.remove(spanbuffer, #spanbuffer)
							spanbuffer.length, spanbuffer.height = aegisub.text_extents(style, table.concat(spanbuffer))
							table.insert(linebuffer, table.concat(spanbuffer))
							linebuffer.length = math.max(linebuffer.length, spanbuffer.length)
							linebuffer.height = linebuffer.height + spanbuffer.height
							spanbuffer = {}
							table.insert(spanbuffer, match.str)
						end
					end
				end
				if #spanbuffer ~= 0 then
					spanbuffer.length, spanbuffer.height = aegisub.text_extents(style, table.concat(spanbuffer))
					table.insert(linebuffer, table.concat(spanbuffer))
					linebuffer.length = math.max(linebuffer.length, spanbuffer.length)
					linebuffer.height = linebuffer.height + spanbuffer.height
					spanbuffer = {}
				end
			end
		end
	end
	
	local wrappedtext = table.concat(linebuffer, "\\N")
	return { width = linebuffer.length, height = linebuffer.height }, wrappedtext
end
