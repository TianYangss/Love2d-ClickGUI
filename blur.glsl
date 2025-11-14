extern number blur_amount;
extern vec2 texture_dimensions;
extern vec2 blur_direction;
vec4 effect(vec4 color, Image ImageTex, vec2 texture_coords, vec2 screen_coords) {
    vec4 sum = vec4(0.0);
    vec2 tex_offset = blur_direction / texture_dimensions * blur_amount;
    sum += Texel(ImageTex, texture_coords - 4.0 * tex_offset) * 0.05;
    sum += Texel(ImageTex, texture_coords - 3.0 * tex_offset) * 0.09;
    sum += Texel(ImageTex, texture_coords - 2.0 * tex_offset) * 0.12;
    sum += Texel(ImageTex, texture_coords - 1.0 * tex_offset) * 0.15;
    sum += Texel(ImageTex, texture_coords) * 0.18;
    sum += Texel(ImageTex, texture_coords + 1.0 * tex_offset) * 0.15;
    sum += Texel(ImageTex, texture_coords + 2.0 * tex_offset) * 0.12;
    sum += Texel(ImageTex, texture_coords + 3.0 * tex_offset) * 0.09;
    sum += Texel(ImageTex, texture_coords + 4.0 * tex_offset) * 0.05;

    return sum * color;
}