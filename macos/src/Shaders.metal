#include <metal_stdlib>
using namespace metal;

struct ITVertex {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
    float4 color    [[attribute(2)]];
};

struct ITUniforms {
    float4x4 projectionMatrix;
};

struct RasterizerData {
    float4 position [[position]];
    float2 texCoord;
    float4 color;
};

vertex RasterizerData it_vertex_shader(uint vertexID [[vertex_id]],
                                       constant ITVertex *vertices [[buffer(0)]],
                                       constant ITUniforms &uniforms [[buffer(1)]]) {
    RasterizerData out;
    float4 pos = float4(vertices[vertexID].position, 0.0, 1.0);
    out.position = uniforms.projectionMatrix * pos;
    out.texCoord = vertices[vertexID].texCoord;
    out.color = vertices[vertexID].color;
    return out;
}

fragment float4 it_fragment_shader(RasterizerData in [[stage_in]],
                                   texture2d<float> colorTexture [[texture(0)]],
                                   sampler textureSampler [[sampler(0)]]) {
    float4 texColor = colorTexture.sample(textureSampler, in.texCoord);
    return texColor * in.color;
}
