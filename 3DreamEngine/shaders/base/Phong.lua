local sh = { }

sh.type = "base"

function sh:getShaderInfoID(dream, mat, shaderType)
	return (mat.tex_normal and 0 or 1) + (mat.tex_emission and 0 or 2)
end

function sh:getShaderInfo(dream, mat, shaderType)
	return {
		tex_normal = mat.tex_normal ~= nil,
		tex_emission = mat.tex_emission ~= nil,
	}
end

function sh:constructDefines(dream, info)
	local code = { }
	if info.tex_normal then
		code[#code+1] = "#define TEX_NORMAL"
		code[#code+1] = "varying mat3 objToWorldSpace;"
	else
		code[#code+1] = "varying vec3 normalV;"
	end
	if info.tex_emission then
		code[#code+1] = "#define TEX_EMISSION"
	end
	
	code[#code+1] = [[
		extern vec4 color_albedo;
		
		#ifdef PIXEL
		extern Image tex_albedo;
		extern Image tex_combined;
		extern vec3 color_combined;
		extern Image tex_emission;
		extern vec3 color_emission;
		extern Image tex_normal;
		#endif
		
		//additional vertex attributes
		#ifdef VERTEX
		attribute highp vec3 VertexNormal;
		attribute highp vec3 VertexTangent;
		attribute highp vec3 VertexBiTangent;
		#endif
	]]
	
	return table.concat(code, "\n")
end

function sh:constructPixelPre(dream, info)
	return [[
	vec4 albedo = Texel(tex_albedo, VaryingTexCoord.xy) * VaryingColor;
	float alpha = albedo.a;
	]]
end

function sh:constructPixel(dream, info)
	return [[
	//transform normal to world space
	#ifdef TEX_NORMAL
		vec3 normal = normalize(objToWorldSpace * normalize(Texel(tex_normal, VaryingTexCoord.xy).rgb - 0.5));
	#else
		vec3 normal = normalize(normalV);
	#endif
	
	//fetch material data
	vec3 rma = Texel(tex_combined, VaryingTexCoord.xy).rgb * color_combined;
	float glossiness = rma.r;
	float specular = rma.g;
	float ao = rma.b;
	
	//emission
	#ifdef TEX_EMISSION
		vec3 emission = Texel(tex_emission, VaryingTexCoord.xy).rgb * color_emission;
	#else
		vec3 emission = color_emission;
	#endif
	]]
end

function sh:constructPixelPost(dream, info)
	return [[
	vec3 viewVec = normalize(viewPos - vertexPos);
	vec3 reflectVec = reflect(-viewVec, normal); 
	
	//ambient component
	vec3 diffuse = reflection(normal, 1.0);
	
	//final ambient color and reflection
	vec3 ref = reflection(reflectVec, 1.0 - glossiness);
	vec3 col = (diffuse + ref * specular) * albedo.rgb * ao;
	
	//emission
	col += emission;
	]]
end

function sh:constructVertex(dream, info)
	return [[
	//transform from tangential space into world space
	mat3 normalTransform = mat3(transform);
	#ifdef TEX_NORMAL
		vec3 T = normalize(normalTransform * (VertexTangent*2.0-1.0));
		vec3 N = normalize(normalTransform * (VertexNormal*2.0-1.0));
		vec3 B = normalize(normalTransform * (VertexBiTangent*2.0-1.0));
		
		objToWorldSpace = mat3(T, B, N);
	#else
		normalV = normalTransform * (VertexNormal*2.0-1.0);
	#endif
	
	//color
	VaryingColor = color_albedo * ConstantColor;
	]]
end

function sh:getLightSignature(dream)
	return "albedo.rgb, specular, glossiness"
end

function sh:perShader(dream, shader, info)
	
end

function sh:perMaterial(dream, shader, info, material)
	local tex = dream.textures
	
	shader:send("tex_albedo", dream:getTexture(material.tex_albedo) or tex.default)
	shader:send("color_albedo", (material.tex_albedo and {1.0, 1.0, 1.0, 1.0} or material.color and {material.color[1], material.color[2], material.color[3], material.color[4] or 1.0} or {1.0, 1.0, 1.0, 1.0}))
	
	shader:send("tex_combined", dream:getTexture(material.tex_combined) or tex.default)
	shader:send("color_combined", {material.tex_glossiness and 1.0 or material.glossiness or 0.5, material.tex_specular and 1.0 or material.specular or 0.5, 1.0})
	
	if info.tex_normal then
		shader:send("tex_normal", dream:getTexture(material.tex_normal) or tex.default_normal)
	end
	
	if info.tex_emission then
		shader:send("tex_emission", dream:getTexture(material.tex_emission) or tex.default)
	end
	shader:send("color_emission", material.emission or (info.tex_emission and {5.0, 5.0, 5.0}) or {0.0, 0.0, 0.0})
end

function sh:perObject(dream, shader, info, task)

end

return sh