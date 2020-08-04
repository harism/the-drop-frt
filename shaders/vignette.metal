#import "common.metal"

fragment float4 RenderVignette(constant float* time [[buffer(0)]],
                               VertexData in [[stage_in]])
{
	float2 uv = in.texturePosition;

    uv *=  1.0 - uv.yx;   //vec2(1.0)- uv.yx; -> 1.-u.yx; Thanks FabriceNeyret !

    float vig = uv.x*uv.y * 15.0; // multiply with sth for intensity

    vig = pow(vig, 0.25); // change pow for modifying the extend of the  vignette

    return float4(vig);
}
