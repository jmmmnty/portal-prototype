shader_type canvas_item;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    tex_color.a = 1.0 - tex_color.r;

    COLOR = tex_color;
}