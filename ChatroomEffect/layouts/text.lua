local layoutdef = {}

layoutdef.type = "text"
layoutdef.priority = 100

layoutdef.measure_minsize = function(layout, size, data)
	-- ��ȡ�ı�ʹ�õ���ʽ��
	local style = style_parse(data.styles, layout.style)

	-- �����ı����з�ʽ
	local wordwrap
	if layout.wordwrap == nil then wordwrap = "none"
	elseif unicode.to_lower_case(layout.wordwrap) == "none" or
		unicode.to_lower_case(layout.wordwrap) == "hard" or
		unicode.to_lower_case(layout.wordwrap) == "soft" then
		wordwrap = unicode.to_lower_case(layout.wordwrap)
	else log_error("wordwrapֵ�ĸ�ʽ����ȷ��")
	end

	-- ��ȡ�ı���
	local text
	if type(layout.text) == string then text = layout.text
	else text = ""
	end
	-- �����ı����֡�
	local wrappedtextminsize, wrappedtext = text_layout(style, wordwrap, size, text)
	
	return wrappedtextminsize
end

layoutdef.do_layout = function(layout, parentlayer, rect, data)
	-- ��ȡ�ı�ʹ�õ���ʽ��
	local style = style_parse(data.styles, layout.style)
	
	-- �����ı����з�ʽ
	local wordwrap
	if layout.wordwrap == nil then wordwrap = "none"
	elseif unicode.to_lower_case(layout.wordwrap) == "none" or
		unicode.to_lower_case(layout.wordwrap) == "hard" or
		unicode.to_lower_case(layout.wordwrap) == "soft" then
		wordwrap = unicode.to_lower_case(layout.wordwrap)
	else log_error("wordwrapֵ�ĸ�ʽ����ȷ��")
	end

	-- ��ȡ�ı���
	local text
	if type(layout.text) == string then text = layout.text
	else text = ""
	end
	-- �����ı����֡�
	local wrappedtextminsize, wrappedtext = text_layout(style, wordwrap, rect, text)
		
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
end

--[[ �����ı�����
---- ������ style, wordwrap, size, text
	style: �ı�ʹ�õġ�
	wordwrap: �ı��Ļ���ģʽ��
	size: ���ڲ��ֵ�Ԥ����Χ��
	text: ��Ҫ������ı���
---- ���أ� minsize, wrappedtext
	 minsize: ���ֺ��ı�ռ�õľ��ε���С��Χ��
	 wrappedtext: ���ֺ���ı���
--]]
local text_layout = function(style, wordwrap, size, text)
	local rawlines = regexutil.split(text, "\\r?\\n")
	local linebuffer = { length = 0 }
	for _, rawline in ipairs(rawlines) do
		if rawline == "" then -- ��Ϊ���У���߶�Ϊ��ʽ�������С��һ�롣
			table.insert(linebuffer, rawline)
			linebuffer.height = linebuffer.height + style.fontsize / 2
		else
			if wordwrap == "none" then -- ������
				table.insert(linebuffer, rawline)
				local w, h, d, el = aegisub.text_extents(style, rawline)
				linebuffer.length = math.max(linebuffer.length, w)
				linebuffer.height = linebuffer.height + h
			else
				regexresult = regexutil.match("\\s+(?=\\S|$)|[\\dA-Za-z]+(?=[^\\dA-Za-z]|$)|\\b.+?\\b|\\S+(?=\\s|$)", rawline)
				
				local spanbuffer = {}
				for _, match in ipairs(regexresult) do
					local wrappable
					if wordwrap == "hard" then -- Ӳ����
						wrappable = true -- �����ı��ξ������ֻ��С�
					elseif wordwrap == "soft" then -- ����
						if regexutil.find("^(\\s+|[\\dA-Za-z]+)$", match.str) then wrappable = false -- �����ֺ���ĸ��������ϲ������ֻ��С�
						else wrappable = true -- ������Ͼ������ֻ��С�
						end
					end
					
					table.insert(spanbuffer, match.str)
					while true do
						local w, h, d, el = aegisub.text_extents(style, table.concat(spanbuffer))
						if size.width == nil or w <= size.width then break
						elseif wrappable or #spanbuffer == 1 then
							table.remove(spanbuffer, #spanbuffer)
							
							for c in unicode.chars(match.str) do
								table.insert(spanbuffer, c)
								local w, h, d, el = aegisub.text_extents(style, table.concat(spanbuffer))
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
