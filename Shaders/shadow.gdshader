shader_type canvas_item;

render_mode unshaded;

uniform float speed : hint_range(0.1, 3.0) = 0.5;
uniform float scale : hint_range(0.1, 5.0) = 1.8;
uniform float color_blend_strength : hint_range(0.1, 2.0) = 1.0;
uniform float gradient_smoothness : hint_range(0.1, 2.0) = 1.5;

// 平滑插值
float smooth_step(float t) {
    return t * t * (3.0 - 2.0 * t);
}

// 噪声函数
float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float noise(vec2 x) {
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0;
    return mix(mix(hash(n), hash(n + 1.0), f.x), mix(hash(n + 57.0), hash(n + 58.0), f.x), f.y);
}

float fbm(vec2 p) {
    float total = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        total += noise(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return total;
}

void fragment() {
    vec2 uv = UV;
    float time = TIME * speed;
    
    // 创建多个层次的渐变
    vec2 uv_scaled = uv * scale;
    
    // 多层流动偏移
    vec2 offset1 = vec2(sin(time * 0.1), cos(time * 0.15)) * 0.2;
    vec2 offset2 = vec2(cos(time * 0.12), sin(time * 0.18)) * 0.15;
    vec2 offset3 = vec2(sin(time * 0.08), cos(time * 0.11)) * 0.1;
    
    // 定义丰富的颜色调色板
    vec3 colors[8];
    colors[0] = vec3(0.416, 0.071, 0.796);  // #6a11cb - 深蓝紫
    colors[1] = vec3(0.145, 0.459, 0.988);  // #2575fc - 蓝色
    colors[2] = vec3(1.0, 0.255, 0.424);    // #ff416c - 红粉
    colors[3] = vec3(1.0, 0.294, 0.169);    // #ff4b2b - 橙红
    colors[4] = vec3(0.067, 0.6, 0.557);    // #11998e - 青绿
    colors[5] = vec3(0.220, 0.937, 0.494);  // #38ef7d - 亮绿
    colors[6] = vec3(0.557, 0.427, 0.949);  // #8e2de2 - 紫色
    colors[7] = vec3(0.976, 0.831, 0.137);  // #f9d423 - 黄色
    
    // 创建多个颜色影响点（固定在屏幕不同位置）
    vec2 points[4];
    points[0] = vec2(0.2, 0.3);  // 左上区域
    points[1] = vec2(0.8, 0.7);  // 右下区域
    points[2] = vec2(0.3, 0.8);  // 左下区域
    points[3] = vec2(0.7, 0.2);  // 右上区域
    
    // 计算每个点对当前像素的影响
    vec3 final_color = vec3(0.0);
    float total_weight = 0.0;
    
    for (int i = 0; i < 4; i++) {
        // 动态颜色选择
        float color_time_offset = float(i) * 0.5;
        float color_phase = mod(time * 0.2 + color_time_offset, 8.0);
        int color_index1 = int(mod(floor(color_phase), 8.0));
        int color_index2 = int(mod(float(color_index1 + 1), 8.0));
        float color_blend = fract(color_phase);
        
        vec3 point_color = mix(colors[color_index1], colors[color_index2], color_blend);
        
        // 计算距离和影响权重
        vec2 dynamic_point = points[i] + vec2(sin(time * 0.1 + float(i)), cos(time * 0.15 + float(i))) * 0.1;
        float dist = length(uv - dynamic_point);
        float weight = 1.0 / (dist + 0.2);  // 避免除零，距离越近影响越大
        weight = pow(weight, 1.5);  // 调整影响衰减
        
        final_color += point_color * weight;
        total_weight += weight;
    }
    
    // 平均化颜色
    if (total_weight > 0.0) {
        final_color /= total_weight;
    }
    
    // 添加对角线渐变层作为基础
    float diagonal = (uv.x + uv.y) * 0.5;
    float diagonal_phase = time * 0.15;
    
    // 动态对角线颜色
    float diag_color_phase1 = mod(diagonal_phase, 8.0);
    float diag_color_phase2 = mod(diagonal_phase + 2.0, 8.0);
    
    int diag_color1_idx = int(mod(floor(diag_color_phase1), 8.0));
    int diag_color2_idx = int(mod(floor(diag_color_phase2), 8.0));
    
    float diag_blend1 = fract(diag_color_phase1);
    float diag_blend2 = fract(diag_color_phase2);
    
    vec3 diag_color1 = mix(colors[diag_color1_idx], colors[int(mod(float(diag_color1_idx + 1), 8.0))], diag_blend1);
    vec3 diag_color2 = mix(colors[diag_color2_idx], colors[int(mod(float(diag_color2_idx + 1), 8.0))], diag_blend2);
    
    vec3 diagonal_gradient = mix(diag_color1, diag_color2, diagonal);
    
    // 添加流动噪声层
    float noise1 = fbm(uv_scaled + offset1 + time * 0.05);
    float noise2 = fbm(uv_scaled * 0.7 + offset2 - time * 0.08);
    
    // 创建基于噪声的渐变影响
    float noise_influence = noise1 * 0.3 + noise2 * 0.2;
    
    // 多层颜色混合确保始终有多色渐变
    vec3 layered_color = mix(final_color, diagonal_gradient, 0.4);
    layered_color = mix(layered_color, mix(colors[0], colors[4], diagonal), 0.2);
    
    // 应用噪声扰动
    vec3 noise_affected = mix(layered_color, 
                             mix(colors[2], colors[6], noise_influence), 
                             0.3 * color_blend_strength);
    
    // 最终颜色混合
    vec3 result_color = mix(noise_affected, final_color, 0.6);
    
    // 添加极微妙的细节层
    float detail1 = fbm(uv * 3.0 + offset3 + time * 0.1) * 0.03 * gradient_smoothness;
    float detail2 = fbm(uv * 5.0 - offset1 * 0.5 + time * 0.15) * 0.02 * gradient_smoothness;
    
    result_color += detail1;
    result_color += detail2;
    
    // 确保颜色值有效
    result_color = clamp(result_color, 0.0, 1.0);
    
    // 最后的平滑处理
    result_color = pow(result_color, vec3(0.95));  // 轻微的伽马校正使过渡更平滑
    
    COLOR = vec4(result_color, 1.0);
}