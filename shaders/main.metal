#import "common.metal"

fragment float4 RenderMain(VertexData in [[stage_in]],
                           texture2d<float> logoTexture [[texture(0)]],
                           texture2d<float> backgroundTexture [[texture(1)]])
{
    constexpr sampler commonSampler(filter::linear, address::clamp_to_zero);

    float2 texturePosition = in.texturePosition * 2.0 - 1.0;
    texturePosition.x *= 1.0 + 0.05 * pow(texturePosition.y, 2.0);
    texturePosition.y *= 1.0 + 0.05 * pow(texturePosition.x, 2.0);
    texturePosition = texturePosition * 0.5 + 0.5;

    constexpr float D = 0.001;
    float4 logoSample = logoTexture.sample(commonSampler, texturePosition + float2(D, D));
    logoSample += logoTexture.sample(commonSampler, texturePosition + float2(-D, D));
    logoSample += logoTexture.sample(commonSampler, texturePosition + float2(-D, -D));
    logoSample += logoTexture.sample(commonSampler, texturePosition + float2(D, -D));
    logoSample *= 0.25;

    float4 backgroundSample = backgroundTexture.sample(commonSampler, texturePosition + float2(D, D));
    backgroundSample += backgroundTexture.sample(commonSampler, texturePosition + float2(-D, D));
    backgroundSample += backgroundTexture.sample(commonSampler, texturePosition + float2(-D, -D));
    backgroundSample += backgroundTexture.sample(commonSampler, texturePosition + float2(D, -D));
    backgroundSample *= 0.25;

    float4 outColor = mix(backgroundSample, logoSample, logoSample.a);
    float luminance = (outColor.r + outColor.g + outColor.b) * 0.5;
    outColor = float4(luminance, luminance, luminance, 1.0);

    float2 uv = in.texturePosition;
    uv *= 1.0 - uv.yx;
    float vig = uv.x * uv.y * 5.0;
    vig = pow(vig, 0.5);
    return outColor * vig;

}
