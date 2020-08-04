#import "common.metal"

#define MAX_ITER 100
#define MAX_DIST 20.0
#define EPSILON 0.001
#define PI 3.14159265

#define HIT_HOLE false
#define HIT_BARREL false

float3 rotateX(float3 p, float ang) {
  float3x3 rmat = float3x3(
    1., 0., 0.,
    0., cos(ang), -sin(ang),
    0., sin(ang), cos(ang));
  return rmat * p;
}

float3 rotateY(float3 p, float ang) {
  float3x3 rmat = float3x3(
    cos(ang), 0., sin(ang),
    0., 1., 0.,
    -sin(ang), 0., cos(ang));
  return rmat * p;
}

float3 rotateZ(float3 p, float ang) {
  float3x3 rmat = float3x3(
    cos(ang), -sin(ang), 0.,
    sin(ang), cos(ang), 0.,
    0., 0., 1.);
  return rmat * p;
}

float sphere(float3 pos, float r) {
  return length(pos) - r;
}

float barrel(float3 pos) {
  float d = sphere(pos, 0.5);
  pos.y += 0.5;
  float holed = -sphere(pos, .25);
  d = max(d, holed);
  //HIT_HOLE = (holed == d) ? true : HIT_HOLE;
  return d;
}

float placedBarrel(float3 pos, float rx, float ry) {
  pos = rotateY(pos, ry);
  pos = rotateX(pos, rx);
  pos.y += 2.0;
  return barrel(pos);
}

float distfunc(float3 pos, float time) {
  pos += float3(time);
  float3 c = float3(10.);
  pos = fmod(pos,c)-0.5*c;

  pos = rotateX(pos, time);

  //HIT_HOLE = false;
  //HIT_BARREL = false;

  // Any of you smart people have a domain transformation way to
  // do a rotational tiling effect instead of this? :)
  float sphered = sphere(pos, 2.0);
  float d = sphered;
  d = min(d, placedBarrel(pos, 0., 0.));
  d = min(d, placedBarrel(pos, 0.8, 0.));
  d = min(d, placedBarrel(pos, 1.6, 0.));
  d = min(d, placedBarrel(pos, 2.4, 0.));
  d = min(d, placedBarrel(pos, 3.2, 0.));
  d = min(d, placedBarrel(pos, 4.0, 0.));
  d = min(d, placedBarrel(pos, 4.8, 0.));
  d = min(d, placedBarrel(pos, 5.6, 0.));
  d = min(d, placedBarrel(pos, 0.8, PI / 2.0));
  d = min(d, placedBarrel(pos, 1.6, PI / 2.0));
  d = min(d, placedBarrel(pos, 2.4, PI / 2.0));
  d = min(d, placedBarrel(pos, 4.0, PI / 2.0));
  d = min(d, placedBarrel(pos, 4.8, PI / 2.0));
  d = min(d, placedBarrel(pos, 5.6, PI / 2.0));
  d = min(d, placedBarrel(pos, 1.2, PI / 4.0));
  d = min(d, placedBarrel(pos, 2.0, PI / 4.0));
  d = min(d, placedBarrel(pos, 1.2, 3.0 * PI / 4.0));
  d = min(d, placedBarrel(pos, 2.0, 3.0 * PI / 4.0));
  d = min(d, placedBarrel(pos, 1.2, 5.0 * PI / 4.0));
  d = min(d, placedBarrel(pos, 2.0, 5.0 * PI / 4.0));
  d = min(d, placedBarrel(pos, 1.2, 7.0 * PI / 4.0));
  d = min(d, placedBarrel(pos, 2.0, 7.0 * PI / 4.0));
  //HIT_BARREL = d != sphered;

  return d;
}

fragment float4 RenderSpores(constant float* time [[buffer(0)]],
                               VertexData in [[stage_in]])

{
    float m_x = in.texturePosition.x - 0.5;
    float m_y = in.texturePosition.y - 0.5;
    float3 cameraOrigin = float3(5.0 * sin(m_x * PI * 2.), m_y * 15.0, 5.0 * cos(m_x * PI * 2.));
    float3 cameraTarget = float3(0.0, 0.0, 0.0);
    float3 upDirection = float3(0.0, 1.0, 0.0);
    float3 cameraDir = normalize(cameraTarget - cameraOrigin);
    float3 cameraRight = normalize(cross(upDirection, cameraOrigin));
    float3 cameraUp = cross(cameraDir, cameraRight);
    float2 screenPos = in.texturePosition * 2.0 - 1.0;
    screenPos.x *= 1280.0 / 720.0;
    float3 rayDir = normalize(cameraRight * screenPos.x + cameraUp * screenPos.y + cameraDir);

    float totalDist = 0.0;
    float3 pos = cameraOrigin;
    float dist = EPSILON;
    for (int i = 0; i < MAX_ITER; i++) {
        if (dist < EPSILON || totalDist > MAX_DIST) { break; }
        dist = distfunc(pos, *time);
        totalDist += dist;
        pos += dist * rayDir;
    }

    if (dist < EPSILON) {
      float2 eps = float2(0.0, EPSILON);
      float3 normal = normalize(float3(
            distfunc(pos + eps.yxx, *time) - distfunc(pos - eps.yxx, *time),
            distfunc(pos + eps.xyx, *time) - distfunc(pos - eps.xyx, *time),
            distfunc(pos + eps.xxy, *time) - distfunc(pos - eps.xxy, *time)));

      float3 lightcol = float3(1.);
      float3 darkcol = float3(.4, .8, .9);
      float sma = 0.4;
      float smb = 0.6;

      if (HIT_HOLE) {
          lightcol = float3(1., 1., 0.8);
      } else if (HIT_BARREL) {
        lightcol.r = 0.95;
      } else {
          sma = 0.2;
          smb = 0.3;
      }
      float facingRatio = smoothstep(sma, smb,
                                     abs(dot(normal, rayDir)));

      float3 illumcol = mix(lightcol, darkcol, 1. - facingRatio);
      return float4(illumcol, 1.0);
    } else {
      float strp = smoothstep(.8, .9, fmod(screenPos.y * 10. + *time, 1.));
      return float4(mix(float3(1., 1., 1.), float3(.4, .8, .9), strp), 1.);
    }
}
