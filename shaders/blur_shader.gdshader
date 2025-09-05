shader_type canvas_item;

uniform float lod: hint_range(0.0, 2.0) = 0.0;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_linear_mipmap;
void fragment(){
	if ( lod <= 2.0){
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, lod);
	COLOR = color.rgba;
	}
	else{
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV, 2.0);
	COLOR = color.rgba;
	}
	}