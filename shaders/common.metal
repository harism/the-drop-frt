#import <metal_stdlib>
#import <simd/simd.h>

using namespace metal;

struct VertexData
{
    float4 position [[position]];
    float4 color;
};
