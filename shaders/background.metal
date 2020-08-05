#import "common.metal"

float m(float d1, float d2)
{
	return min(d1, d2);
}

float l(float2 p, float2 start, float2 end, float width)
{
	float2 dir = start - end;
	float lngth = length(dir);
	dir /= lngth;
	float2 proj = max(0.0, min(lngth, dot((start - p), dir))) * dir;
	return length( (start - p) - proj ) - (width / 2.0);
}

fragment float4 RenderBackground(constant float* time [[buffer(0)]],
                                 constant int* powerIndex [[buffer(1)]],
                                 constant float* peakPowerValues [[buffer(2)]],
                                 constant float* averagePowerValues [[buffer(3)]],
                                 VertexData in [[stage_in]])
{
    float d = 1.0;

    for (int index = 0; index < 255; ++index)
    {
        int readIndex = (index + *powerIndex) & 0xFF;
        float xx1 = (1920.0 / 256.0) * index;
        float xx2 = (1920.0 / 256.0) * (index + 1);
        float yy1 = 940.0 + averagePowerValues[readIndex] * 50.0;
        float yy2 = 940.0 + averagePowerValues[(readIndex + 1) & 0xFF] * 50.0;
        d = m(d, l(in.screenPosition, float2(xx1, yy1), float2(xx2, yy2), 10.0));
    }

    d = saturate(saturate(d) + 0.5);
    return saturate(float4(d, d, d, 1.0));
}
