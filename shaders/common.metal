#import <metal_stdlib>
#import <simd/simd.h>

using namespace metal;

struct VertexData
{
    float4 position [[position]];
    float4 color;
};

vertex VertexData RenderScreen(uint vertexId [[vertex_id]])
{
    VertexData out;

    switch (vertexId)
    {
        case 0:
            out.position = float4(-1.0, 1.0, 0.0, 1.0);
            out.color = float4(1.0, 0.0, 0.0, 1.0);
            break;
        case 1:
            out.position = float4(-1.0, -1.0, 0.0, 1.0);
            out.color = float4(0.0, 1.0, 0.0, 1.0);
            break;
        case 2:
            out.position = float4(1.0, 1.0, 0.0, 1.0);
            out.color = float4(0.0, 0.0, 1.0, 1.0);
            break;
        case 3:
            out.position = float4(1.0, -1.0, 0.0, 1.0);
            out.color = float4(1.0, 1.0, 0.0, 1.0);
            break;
    }

    return out;
}

fragment float4 RenderTest(VertexData in [[stage_in]])
{
    return in.color;
}

