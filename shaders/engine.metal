#import "common.metal"

// Combine distance field functions

float smoothMerge(float d1, float d2, float k)
{
    float h = clamp(0.5 + 0.5*(d2 - d1)/k, 0.0, 1.0);
    return mix(d2, d1, h) - k * h * (1.0-h);
}

float merge(float d1, float d2)
{
	return min(d1, d2);
}

float mergeExclude(float d1, float d2)
{
	return min(max(-d1, d2), max(-d2, d1));
}

float substract(float d1, float d2)
{
	return max(-d1, d2);
}

float intersect(float d1, float d2)
{
	return max(d1, d2);
}

// Rotation and translation

float2 rotateCCW(float2 p, float a)
{
	float2x2 m = float2x2(cos(a), sin(a), -sin(a), cos(a));
	return p * m;
}

float2 rotateCW(float2 p, float a)
{
	float2x2 m = float2x2(cos(a), -sin(a), sin(a), cos(a));
	return p * m;
}

float2 translate(float2 p, float2 t)
{
	return p - t;
}

// Distance field functions

float pie(float2 p, float angle)
{
	angle = (angle * 3.1415926536) / 360.0;
	float2 n = float2(cos(angle), sin(angle));
	return abs(p).x * n.x + p.y*n.y;
}

float circleDist(float2 p, float radius)
{
	return length(p) - radius;
}

float triangleDist(float2 p, float radius)
{
	return max(	abs(p).x * 0.866025 +
			   	p.y * 0.5, -p.y)
				-radius * 0.5;
}

float triangleDist(float2 p, float width, float height)
{
	float2 n = normalize(float2(height, width / 2.0));
	return max(	abs(p).x*n.x + p.y*n.y - (height*n.y), -p.y);
}

float semiCircleDist(float2 p, float radius, float angle, float width)
{
	width /= 2.0;
	radius -= width;
	return substract(pie(p, angle),
					 abs(circleDist(p, radius)) - width);
}

float boxDist(float2 p, float2 size, float radius)
{
	size -= float2(radius);
	float2 d = abs(p) - size;
  	return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - radius;
}

float lineDist(float2 p, float2 start, float2 end, float width)
{
	float2 dir = start - end;
	float lngth = length(dir);
	dir /= lngth;
	float2 proj = max(0.0, min(lngth, dot((start - p), dir))) * dir;
	return length( (start - p) - proj ) - (width / 2.0);
}

// Masks for drawing

float fillMask(float dist)
{
	return clamp(-dist, 0.0, 1.0);
}

float innerBorderMask(float dist, float width)
{
	//dist += 1.0;
	float alpha1 = clamp(dist + width, 0.0, 1.0);
	float alpha2 = clamp(dist, 0.0, 1.0);
	return alpha1 - alpha2;
}

float outerBorderMask(float dist, float width)
{
	//dist += 1.0;
	float alpha1 = clamp(dist, 0.0, 1.0);
	float alpha2 = clamp(dist - width, 0.0, 1.0);
	return alpha1 - alpha2;
}

// Scene rendering

float calcStaticParts(float2 p)
{
    float d = semiCircleDist(translate(p, float2(960.0, 800.0)), 200.0, 90.0, 20.0);
    d = merge(d, semiCircleDist(translate(p, float2(960.0, 800.0)), 40.0, 0.0, 20.0));
    d = merge(d, lineDist(p, float2(830.0, 662.0), float2(830.0, 150.0), 20.0));
    d = merge(d, lineDist(p, float2(1090.0, 662.0), float2(1090.0, 150.0), 20.0));
    d = merge(d, lineDist(p, float2(870.0, 110.0), float2(1050.0, 110.0), 20.0));
    return d;
}

float calcCrankshaft(float2 p, float angle)
{
    float d = semiCircleDist(rotateCCW(translate(p, float2(960.0, 800.0)), angle), 160.0, 180.0, 20.0);
    d = merge(d, boxDist(rotateCCW(translate(p, float2(960.0, 800.0)), angle), float2(160.0, 10.0), 10.0));
    d = merge(d, boxDist(translate(rotateCCW(translate(p, float2(960.0, 800.0)), angle), float2(0.0, -70.0)), float2(40.0, 100.0), 40.0));
    d = substract(boxDist(translate(rotateCCW(translate(p, float2(960.0, 800.0)), angle), float2(0.0, -70.0)), float2(20.0, 80.0), 20.0), d);
    return d;
}

float calcLines(float2 p, float angle)
{
    float xDiff = sin(angle) * 130.0;
    float yDiff = -cos(angle) * 130.0;
    float yDiff2 = sqrt((350.0 * 350.0) - (xDiff * xDiff));

    float d = lineDist(p, float2(960.0, 800.0 + yDiff - yDiff2), float2(960.0 + xDiff, 800.0 + yDiff), 20.0);
    d = merge(d, lineDist(p, float2(830.0, 650.0 + yDiff - yDiff2), float2(1090.0, 650.0 + yDiff - yDiff2), 20.0));
    d = merge(d, lineDist(p, float2(830.0, 700.0 + yDiff - yDiff2), float2(1090.0, 700.0 + yDiff - yDiff2), 20.0));
    d = merge(d, lineDist(p, float2(830.0, 800.0 + yDiff - yDiff2), float2(1090.0, 800.0 + yDiff - yDiff2), 20.0));
    return d;
}

float calcValves(float2 p, float angle)
{
    float2 diffLeft = saturate(float2(sin((angle - 30.0) * 2.0))) * 50.0;
    float2 diffRight = saturate(float2(cos(angle * 2.0))) * 50.0;
    diffRight.y = -diffRight.y;

    if (fmod(angle, 2.0 * 3.1415) > 3.1415)
    {
        diffLeft = diffRight = float2(0.0);
    }

    float d = lineDist(p, float2(830.0, 150.0) - diffLeft, float2(830.0, 110.0) - diffLeft, 20.0);
    d = merge(d, lineDist(p, float2(830.0, 110.0) - diffLeft, float2(870.0, 110.0) - diffLeft, 20.0));
    d = merge(d, lineDist(p, float2(830.0, 110.0) - diffLeft, float2(790.0, 70.0) - diffLeft, 20.0));

    d = merge(d, lineDist(p, float2(1090.0, 150.0) + diffRight, float2(1090.0, 110.0) + diffRight, 20.0));
    d = merge(d, lineDist(p, float2(1090.0, 110.0) + diffRight, float2(1050.0, 110.0) + diffRight, 20.0));
    d = merge(d, lineDist(p, float2(1090.0, 110.0) + diffRight, float2(1130.0, 70.0) + diffRight, 20.0));

    return d;
}

fragment float4 RenderEngine(constant float* time [[buffer(0)]],
                             VertexData in [[stage_in]])
{
    float2 p = in.screenPosition;
    p.y = 1080.0 - p.y;

    float angle = pow(*time, 1.2);

    float d = calcStaticParts(p);
    d = merge(d, calcCrankshaft(p, angle));
    d = merge(d, calcLines(p, angle));
    d = merge(d, calcValves(p, angle));

    return saturate(float4(d, d, d, d <= 0.0 ? 1.0 : 0.0));
}
