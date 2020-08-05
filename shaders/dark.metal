#import "common.metal"

fragment float4 RenderDark(constant float* time [[buffer(0)]],
                           constant int* powerIndex [[buffer(1)]],
                           constant float* peakPowerValues [[buffer(2)]],
                           constant float* averagePowerValues [[buffer(3)]],
                           VertexData in [[stage_in]])
{
    float c = saturate(0.2 + averagePowerValues[*powerIndex]);
    return float4(c, c, c, 1.0);
}
