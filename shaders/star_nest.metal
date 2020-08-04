#include "common.metal"

// Star Nest by Pablo Roman Andrioli
// This content is under the MIT License.

#define iterations 17
#define formuparam 0.53

#define volsteps 20
#define stepsize 0.1

#define zoom   0.800
#define tile   0.850
#define speed  0.010

#define brightness 0.0015
#define darkmatter 0.300
#define distfading 0.730
#define saturation 0.850

fragment float4 RenderStarNest(constant float* time [[buffer(0)]],
                               VertexData in [[stage_in]])
{
	//get coords and direction
	float2 uv = in.screenPosition / float2(1280.0, 720.0) - 0.5;
	uv.y *= 720.0 / 1280.0;
	float3 dir = float3(uv * zoom, 1.0);

	//mouse rotation
	float a1 = 0.1 + fmod(*time * 0.001, 1.0);
	float a2 = 0.3 + fmod(*time * 0.001, 1.0);
	float2x2 rot1 = float2x2(cos(a1), sin(a1), -sin(a1), cos(a1));
	float2x2 rot2 = float2x2(cos(a2), sin(a2), -sin(a2), cos(a2));
	dir.xz = dir.xz * rot1;
	dir.xy = dir.xy * rot2;
	float3 from = float3(1.0, 0.5, 0.5);
	from += float3(*time * 2.0 * 0.01, *time * 0.01, -2.0);
	from.xz = from.xz * rot1;
	from.xy = from.xy * rot2;

	//volumetric rendering
	float s = 0.1;
    float fade = 1.0;
	float3 v = float3(0.0);

	for (int r = 0; r < volsteps; r++)
    {
		float3 p = from + s * dir * 0.5;
		p = abs(float3(tile) - fmod(p, float3(tile * 2.0))); // tiling fold
        float a = 0.0;
		float pa = 0.0;

		for (int i = 0; i < iterations; i++)
        {
			p = abs(p) / dot(p,p) - formuparam; // the magic formula
			a += abs(length(p) - pa); // absolute sum of average change
			pa = length(p);
		}

		float dm = max(0.0, darkmatter - a * a * 0.001); //dark matter
		a *= a * a; // add contrast
		if (r > 6) fade *= 1.0 - dm; // dark matter, don't render near
		//v+=vec3(dm,dm*.5,0.);
		v += fade;
		v += float3(s, s * s, s * s * s * s) * a * brightness * fade; // coloring based on distance
		fade *= distfading; // distance fading
		s += stepsize;
	}

	v = mix(float3(length(v)), v, saturation); //color adjust
	return float4(v * 0.01, 1.0);
}
