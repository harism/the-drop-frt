#import "common.metal"

fragment float4 RenderBlank(constant float* time [[buffer(0)]],
                            VertexData in [[stage_in]])
{
    return float4(1.0);
}
