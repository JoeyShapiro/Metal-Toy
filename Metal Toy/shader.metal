//
//  shader.metal
//  Metal Toy
//
//  Created by Joey Shapiro on 11/12/24.
//


#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 resolution;
    float2 scale;
};

constant bool useConstants [[function_constant(0)]];

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                              constant float2 *vertices [[buffer(0)]]) {
    VertexOut out;
    out.position = float4(vertices[vertexID], 0.0, 1.0);
    out.uv = vertices[vertexID].xy;
    
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                               constant Uniforms &uniforms [[buffer(0)]]) {
    float3 color = float3(0);
    
    return float4(color, 1);
}
