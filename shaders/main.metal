#import "common.metal"

fragment float4 RenderMain(VertexData in [[stage_in]],
                           texture2d<float> engineTexture [[texture(0)]],
                           texture2d<float> backgroundTexture [[texture(1)]])
{
    constexpr sampler commonSampler(filter::linear, address::clamp_to_zero, coord::pixel);

    float2 texturePosition = in.texturePosition * 2.0 - 1.0;
    texturePosition.x *= 1.0 + 0.05 * pow(texturePosition.y, 2.0);
    texturePosition.y *= 1.0 + 0.05 * pow(texturePosition.x, 2.0);
    texturePosition = texturePosition * 0.5 + 0.5;
    float2 texturePixelPosition = texturePosition * float2(1920.0, 1080.0);

    const float D = 0.001;
    float4 engineSample = engineTexture.sample(commonSampler, texturePixelPosition);
    engineSample += engineTexture.sample(commonSampler, texturePixelPosition + float2(1.0, 1.0));
    engineSample += engineTexture.sample(commonSampler, texturePixelPosition + float2(1.0, -1.0));
    engineSample += engineTexture.sample(commonSampler, texturePixelPosition + float2(-1.0, 1.0));
    engineSample += engineTexture.sample(commonSampler, texturePixelPosition + float2(-1.0, -1.0));
    engineSample *= 0.2;

    float4 backgroundSample = backgroundTexture.sample(commonSampler, texturePixelPosition);
    float4 outColor = mix(backgroundSample, engineSample, engineSample.a);

    float luminance = (outColor.r + outColor.g + outColor.b) * 0.5;
    outColor = float4(luminance, luminance, luminance, 1.0);

    float2 vignettePosition = in.texturePosition;
    vignettePosition *= 1.0 - vignettePosition.yx;
    outColor *= pow(vignettePosition.x * vignettePosition.y * 5.0, 0.5);
    outColor = saturate(outColor);

    if (fmod(texturePixelPosition.x, 50.0) <= 2 || fmod(texturePixelPosition.y, 50.0) <= 2)
    {
        outColor = outColor * float4(0.95, 0.95, 0.95, 1.0);
    }

    return outColor;
}
