#import "common.metal"

vertex VertexData RenderScreenQuad(uint vertexId [[vertex_id]])
{
    VertexData out;

    switch (vertexId)
    {
        case 0:
            out.position = float4(-1.0, 1.0, 0.0, 1.0);
            out.screenPosition = float2(0.0, 720.0);
            out.texturePosition = float2(0.0, 0.0);
            break;
        case 1:
            out.position = float4(-1.0, -1.0, 0.0, 1.0);
            out.screenPosition = float2(0.0, 0.0);
            out.texturePosition = float2(0.0, 1.0);
            break;
        case 2:
            out.position = float4(1.0, 1.0, 0.0, 1.0);
            out.screenPosition = float2(1280.0, 720.0);
            out.texturePosition = float2(1.0, 0.0);
            break;
        case 3:
            out.position = float4(1.0, -1.0, 0.0, 1.0);
            out.screenPosition = float2(1280.0, 0.0);
            out.texturePosition = float2(1.0, 1.0);
            break;
    }

    return out;
}
