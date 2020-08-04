#import "common.metal"

// Noise animation - Electric
// by nimitz (stormoid.com) (twitter: @stormoid)
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
// Contact the author for other licensing options

//The domain is displaced by two fbm calls one for each axis.
//Turbulent fbm (aka ridged) is used for better effect.

#define tau 6.2831853

float2x2 makem2(float theta){float c = cos(theta);float s = sin(theta);return float2x2(c,-s,s,c);}
float noise(float2 p)
{
    p *= 10000.0;
    return fract(sin(float2(dot(p,float2(127.1,311.7)),dot(p,float2(269.5,183.3))))*43758.5453).y;
}

float fbm(float2 p)
{
	float z=2.;
	float rz = 0.;
	for (float i= 1.;i < 6.;i++)
	{
		rz+= abs((noise(p)-0.5)*2.)/z;
		z = z*2.;
		p = p*2.;
	}
	return rz;
}

float dualfbm(float2 p, float time)
{
    //get two rotated fbm calls and displace the domain
	float2 p2 = p*.7;
	float2 basis = float2(fbm(p2-time*1.6),fbm(p2+time*1.7));
	basis = (basis-.5)*.2;
	p += basis;

	//coloring
	return fbm(p*makem2(time*0.2));
}

float circ(float2 p)
{
	float r = length(p);
	r = log(sqrt(r));
	return abs(fmod(r*4.,tau)-3.14)*3.+.2;

}

fragment float4 RenderElectric(constant float* time [[buffer(0)]],
                               VertexData in [[stage_in]])
{
	//setup system
	float2 p = in.screenPosition / float2(1280.0, 720.0) - 0.5;
	p.x *= 1280.0 / 720.0;
	p*=4.;

    float rz = dualfbm(p, *time);

	//rings
	p /= exp(fmod(*time,3.14159));
	rz *= pow(abs((0.1-circ(p))),.9);

	//final color
	float3 col = float3(.2,0.1,0.4)/rz;
	col=pow(abs(col),float3(.99));
	return float4(col * 4.0,1.);
}
