local logic = {}

logic.type = "image"
logic.priority = 100

logic.measure_minsize = function(layout, size, meta, data)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	if scalemode == "none" then -- ͼƬ�����䣬���������졣
		return {
			width = image.rect.width,
			height = image.rect.height
		}
	elseif scalemode == "fill" then -- ͼƬ�������С����Ӧ���÷�Χ������ȿ��ܸı䡣
		return {
			width = size.width or 0,
			height = size.height or 0
		}
	elseif scalemode == "aspectfit" then -- ͼƬ�������С����Ѵ�С��������ʾ������һ�������������÷�Χ�����ֳ���Ȳ��䡣
		local scale
		if size.width == nil and size.height == nil then scale = 0
		elseif size.width == nil then scale = (size.height or image.rect.height) / image.rect.height
		elseif size.height == nil then scale = (size.width or image.rect.width) / image.rect.width
		else scale = math.min((size.width or image.rect.width) / image.rect.width, (size.height or image.rect.height) / image.rect.height)
		end
		return {
			width = math.floor(image.rect.width * scale + 0.5),
			height = math.floor(image.rect.height * scale + 0.5)
		}
	elseif scalemode == "aspectfill" then -- ͼƬ�ڲ��ı䳤��ȵ�ǰ�����������С���������������÷�Χ�������ܻᱻ�ü���
		local scale
		if size.width == nil and size.height == nil then scale = 0
		elseif size.width == nil then scale = (size.height or image.rect.height) / image.rect.height
		elseif size.height == nil then scale = (size.width or image.rect.width) / image.rect.width
		else scale = math.max((size.width or image.rect.width) / image.rect.width, (size.height or image.rect.height) / image.rect.height)
		end
		return {
			width = math.floor(image.rect.width * scale + 0.5),
			height = math.floor(image.rect.height * scale + 0.5)
		}
	end
end

logic.do_layout = function(layout, rect, meta, data)
	-- ��ȡ���ֵ�Ԫ���ݡ�
	meta = parse_meta(layout, size, meta, data)
	
	local newimagesize
	if scalemode == "none" then -- ͼƬ�����䣬���������졣
		newimagesize = {
			width = image.rect.width,
			height = image.rect.height
		}
	elseif scalemode == "fill" then -- ͼƬ�������С����Ӧ���÷�Χ������ȿ��ܸı䡣
		newimagesize = {
			width = rect.width,
			height = rect.height
		}
	elseif scalemode == "aspectfit" then -- ͼƬ�������С����Ѵ�С��������ʾ������һ�������������÷�Χ�����ֳ���Ȳ��䡣
		local scale = math.min(rect.width / image.rect.width, rect.height / image.rect.height)
		newimagesize = {
			width = math.floor(image.rect.width * scale + 0.5),
			height = math.floor(image.rect.height * scale + 0.5)
		}
	elseif scalemode == "aspectfill" then -- ͼƬ�ڲ��ı䳤��ȵ�ǰ�����������С���������������÷�Χ�������ܻᱻ�ü���
		local scale = math.max(rect.width / image.rect.width, rect.height / image.rect.height)
		newimagesize = {
			width = math.floor(image.rect.width * scale + 0.5),
			height = math.floor(image.rect.height * scale + 0.5)
		}
	end
	image.scaleto = newimagesize
	result = {
		layouttype = "image",
		rect = {
			x = nil,
			y = nil,
			width = newimagesize.width,
			height = newimagesize.height
		},
		image = image,
	}
	
	return result
end

local parse_meta = function(layout, size, data, meta)
	meta = util.copy(meta or {})
	
	-- ����ͼ�������ģʽ��
	if layout.scalemode == nil then meta.scalemode = "aspectfit"
	elseif unicode.to_lower_case(layout.scalemode) == "none" or
		unicode.to_lower_case(layout.scalemode) == "fill" or
		unicode.to_lower_case(layout.scalemode) == "aspectfit" or
		unicode.to_lower_case(layout.scalemode) == "aspectfill" then
		meta.scalemode = unicode.to_lower_case(layout.scalemode)
	else log_error("scalemodeֵ�ĸ�ʽ����ȷ��")
	end
	
	-- ��ȡͼƬ��Ϣ
	meta.image = image_parse(layout.image)
	
	return meta
end

local image_parse = function(image)
	if image == nil then return nil
	elseif type(image) == "string" then
		local info = interop.image.getinfo[image]
		return {
			source = info,
			rect = {
				x = 0,
				y = 0,
				width = info.width,
				height = info.height
			}
		}
	elseif type(image) == "table" then
		if type(image.source) == "string" then
			local info = interop.image.getinfo[image.source]
			return {
				source = info,
				rect = {
					x = tonumber(image.x) or 0,
					y = tonumber(image.y) or 0,
					width = tonumber(image.width) or info.width,
					height = tonumber(image.height) or info.height
				}
			}
		else log_error("sourceֵ�ĸ�ʽ����ȷ��")
		end
	end

	log_error("imageֵ�ĸ�ʽ����ȷ��")
end