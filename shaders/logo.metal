#import "common.metal"

#define MAX_MARCHING_STEPS 255
#define MIN_DIST 0.0
#define MAX_DIST 100.0
#define EPSILON 0.0001

float boxSDF(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float cylinderSDF(float3 p, float h, float r)
{
    float2 d = abs(float2(length(p.xz),p.y)) - float2(h,r);
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float3x3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return float3x3(
        float3(c, 0, s),
        float3(0, 1, 0),
        float3(-s, 0, c)
    );
}

float3x3 shearX(float theta) {
   	return float3x3(
        float3(1, 0, 0),
        float3(0, 1, 0),
        float3(theta, 0, 1)
    );
}

float3x3 shearY(float theta) {
   	return float3x3(
        float3(1, 0, theta),
        float3(0, 1, 0),
        float3(0, 0, 1)
    );
}

float subtractionSDF(float d1, float d2 ) {
    return max(-d1, d2);
}

float unionSDF(float distA, float distB) {
    return min(distA, distB);
}

float3 rayDirection(float2 size, float2 fragCoord) {
    float2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(0.5);
    return normalize(float3(xy, -z));
}

float sceneSDF(float3 samplePoint, float time) {
    samplePoint = rotateY(time) * samplePoint;

    float cylinder = cylinderSDF(samplePoint, 3.0, 0.3);
    float cylinderNeg = cylinderSDF(samplePoint, 2.4, 0.31);

    float char1 = boxSDF(shearY(0.65) * rotateY(0.523599) * (samplePoint + float3(1.0, 0.0, -0.3)), float3(0.3, 0.3, 1.05));
    float char2 = boxSDF(shearY(-0.6) *  rotateY(-0.523599) * (samplePoint + float3(0.3, 0.0, -0.3)), float3(0.3, 0.3, 0.95));

    float char3 = boxSDF(shearY(-0.65) * rotateY(-0.523599) * (samplePoint + float3(-1.0, 0.0, -0.3)), float3(0.3, 0.3, 1.05));
    float char4 = boxSDF(shearY(0.6) * rotateY(0.523599) * (samplePoint + float3(-0.3, 0.0, -0.3)), float3(0.3, 0.3, 0.95));

    float char5 = boxSDF(shearX(0.5) * (samplePoint + float3(2.71, 0.0, 0.6)), float3(1.197, 0.3, 0.32));
    float char6 = boxSDF(samplePoint + float3(-1.97, 0.0, 0.6), float3(0.61, 0.3, 0.32));

    float char7 = boxSDF(samplePoint + float3(-2.7, 0.0, -0.1), float3(0.5, 0.31, 0.38));

    float retVal = subtractionSDF(cylinderNeg, cylinder);
    retVal = unionSDF(retVal, char1);
    retVal = unionSDF(retVal, char2);
    retVal = unionSDF(retVal, char3);
    retVal = unionSDF(retVal, char4);
    retVal = unionSDF(retVal, char5);
    retVal = unionSDF(retVal, char6);
    retVal = subtractionSDF(char7, retVal);

    return retVal;
}

float3 estimateNormal(float3 p, float time) {
    return normalize(float3(
        sceneSDF(float3(p.x + EPSILON, p.y, p.z), time) - sceneSDF(float3(p.x - EPSILON, p.y, p.z), time),
        sceneSDF(float3(p.x, p.y + EPSILON, p.z), time) - sceneSDF(float3(p.x, p.y - EPSILON, p.z), time),
        sceneSDF(float3(p.x, p.y, p.z  + EPSILON), time) - sceneSDF(float3(p.x, p.y, p.z - EPSILON), time)
    ));
}

float3 phongContribForLight(float3 k_d, float3 k_s, float alpha, float3 p, float3 eye,
                          float3 lightPos, float3 lightIntensity, float time) {
    float3 N = estimateNormal(p, time);
    float3 L = normalize(lightPos - p);
    float3 V = normalize(eye - p);
    float3 R = normalize(reflect(-L, N));

    float dotLN = dot(L, N);
    float dotRV = dot(R, V);

    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return float3(0.0, 0.0, 0.0);
    }

    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

float3 phongIllumination(float3 k_a, float3 k_d, float3 k_s, float alpha, float3 p, float3 eye, float time) {
    const float3 ambientLight = 0.5 * float3(1.0, 1.0, 1.0);
    float3 color = ambientLight * k_a;

    float3 light1Pos = float3(4.0 * sin(time * 1.0),
                              2.0,
                              4.0 * cos(time * 1.0));
    float3 light1Intensity = float3(0.2, 0.6, 1.0);

    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity,
                                  time);

    float3 light2Pos = float3(2.0 * sin(0.37 * time),
                              2.0 * cos(0.37 * time),
                              2.0);
    float3 light2Intensity = float3(0.2, 0.6, 1.0);

    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity,
                                  time);
    return color;
}

float shortestDistanceToSurface(float3 eye, float3 marchingDirection, float start, float end, float time) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        float dist = sceneSDF(eye + depth * marchingDirection, time);
        if (dist < EPSILON) {
			return depth;
        }
        depth += dist;
        if (depth >= end) {
            return end;
        }
    }
    return end;
}

float3x3 viewMatrix(float3 eye, float3 center, float3 up) {
    float3 f = normalize(center - eye);
    float3 s = normalize(cross(f, up));
    float3 u = cross(s, f);
    return float3x3(s, u, -f);
}

fragment float4 RenderLogo(constant float* time [[buffer(0)]],
                           VertexData in [[stage_in]])
{
	float3 viewDir = rayDirection(float2(1920, 1200), in.position.xy);
    float3 eye = float3(0.0, -25.0, 10.0);

    float3x3 viewToWorld = viewMatrix(eye, float3(0.0, 0.0, 0.0), float3(0.0, 1.0, 0.0));

    float3 worldDir = viewToWorld * viewDir;

    float dist = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST, *time);

    if (dist > MAX_DIST - EPSILON) {
        // Didn't hit anything
        return float4(0.0, 0.0, 0.0, 0.0);
    }

	// The closest point on the surface to the eyepoint along the view ray
    float3 p = eye + dist * worldDir;

	// Use the surface normal as the ambient color of the material
    float3 K_a = float3(0.2, 0.6, 1.0);
    float3 K_d = K_a;
    float3 K_s = float3(1.0, 1.0, 1.0);
    float shininess = 8.0;

    float3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye, *time);

    float scan = fmod(dist + *time, 20.0);
    scan = max(scan, fmod((dist + *time) * 0.226, 20.0));
    if (scan > 15.0) color.r += color.b * 0.5;

   	return float4(color, 1.0);
}
