#import "common.metal"

fragment float4 RenderBlank(constant float* time [[buffer(0)]],
                            constant int* powerIndex [[buffer(1)]],
                            constant float* peakPowerValues [[buffer(2)]],
                            constant float* averagePowerValues [[buffer(3)]],
                            VertexData in [[stage_in]])
{
    float c = clamp(1.0 - peakPowerValues[*powerIndex] * *time * 0.0003, 0.0, 1.2);
    return float4(c, c, c, 1.0);
}
