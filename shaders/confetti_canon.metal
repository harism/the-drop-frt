#import "common.metal"

// Code by Flopine
// Thanks to wsmind and leon for teaching me :)


#define PI 3.141592
#define TAU 2.*PI

float2x2 rot (float a)
{
    float c = cos(a);
    float s = sin(a);
    return float2x2(c,s,-s,c);
}


float2 moda (float2 p, float per)
{
    float a = atan2(p.y,p.x);
    float l = length(p);
    a = fmod(a-per/2.,per)-per/2.;
    return float2 (cos(a),sin(a))*l;
}

// iq's palette http://www.iquilezles.org/www/articles/palettes/palettes.htm
float3 palette(float t, float3 a, float3 b, float3 c, float3 d )
{
    return a + b*cos(TAU*(c*t+d));
}


float sphe (float3 p, float r)
{
    return length(p)-r;
}

float box (float3 p, float3 c)
{
    return length(max(abs(p)-c,0.));
}

float prim (float3 p)
{
    float b = box(p, float3(1.));
    float s = sphe(p,1.3);
    return max(-s, b);
}

float row (float3 p, float per)
{
	p.y = fmod(p.y-per/2., per)-per/2.;
    return prim(p);
}

float squid (float3 p, float time)
{
    p.xz = p.xz * rot(PI/2.);
    p.yz = moda(p.yz, TAU/5.);
    p.z += sin(p.y+time*2.);
    return row(p,1.5);
}

float SDF(float3 p, float time)
{
    p.xz = p.xz * rot (time*.8);
    p.yz = p.yz * rot(time*0.2);
    p.xz = moda(p.xz, TAU/12.);
    return squid(p, time);
}



fragment float4 RenderConfettiCanon(constant float* time [[buffer(0)]],
                                    VertexData in [[stage_in]])
{
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = 2.*(in.screenPosition/float2(1280.0, 720.0))-1.;
	uv.x *= 0.1 * (1280.0 / 720.0);
    uv.y = uv.y * 0.1 - 0.2;

    float3 p = float3 (0.01,3.,-8.);
    float3 dir = normalize(float3(uv*2.,1.));

    float shad = 1.;

    for (int i=0;i<60;i++)
    {
        float d = SDF(p, *time);
        if (d<0.001)
        {
            shad = float(i)/60.;
            break;
        }
        p += d*dir*0.5;
    }

    float3 pal = palette(p.z,
        				float3(0.5),
                      float3(0.5),
                      float3(.2),
                      float3(0.,0.3,0.5)
                      );
    // Time varying pixel color
    float3 col = float3(1.-shad)*pal;

    // Output to screen
    return float4(pow(col, float3(0.45)),1.0);
}
