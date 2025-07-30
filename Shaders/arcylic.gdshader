// Acrylic Panel Shader - Godot 4.4 兼容版
shader_type canvas_item;
render_mode blend_mix;

// ✅ 使用 hint_screen_texture 正确获取屏幕纹理
uniform sampler2D screen_texture : hint_screen_texture;

// 模糊强度（像素偏移量）
uniform float blur_strength : hint_range(0.0, 5.0) = 1.0;

// 整体透明度
uniform float global_opacity : hint_range(0.0, 1.0) = 0.3;

// 噪点控制
uniform bool use_noise = true;
uniform float noise_intensity : hint_range(0.0, 0.1) = 0.03;
uniform float noise_scale : hint_range(0.1, 10.0) = 4.0;

// 简单哈希生成噪点
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec3 color = vec3(0.0);

    // 模糊核（3x3 高斯近似）
    float kernel[9];
    kernel[0] = 0.109; kernel[1] = 0.118; kernel[2] = 0.109;
    kernel[3] = 0.118; kernel[4] = 0.132; kernel[5] = 0.118;
    kernel[6] = 0.109; kernel[7] = 0.118; kernel[8] = 0.109;

    // 模糊采样
    for (int i = 0; i < 9; i++) {
        ivec2 offset = ivec2(i % 3 - 1, i / 3 - 1);
        vec2 uv_offset = vec2(offset) * blur_strength / SCREEN_PIXEL_SIZE;
        vec2 sample_uv = SCREEN_UV + uv_offset;

        // ✅ 使用 screen_texture uniform 而不是 SCREEN_TEXTURE
        color += kernel[i] * texture(screen_texture, sample_uv).rgb;
    }

    // 添加亚克力色调（轻微蓝灰）
    color = mix(color, vec3(0.15, 0.18, 0.25), 0.2);

    // 叠加噪点
    if (use_noise) {
        float noise = hash(SCREEN_UV * noise_scale) * noise_intensity;
        color += noise;
    }

    // 输出最终颜色（带透明度）
    COLOR = vec4(color, global_opacity);
}