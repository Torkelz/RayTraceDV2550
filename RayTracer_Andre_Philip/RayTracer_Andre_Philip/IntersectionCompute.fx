#ifndef INTERSECTIONCOMPUTE
#define INTERSECTIONCOMPUTE
#include "structsCompute.fx"

#define float_MAX 3.4f * 10^38
#define EPSILON 0.0001f

float RaySphereIntersect(Ray r, Sphere sp)
{
	float3 l = sp.position - r.origin;
	float s = dot(l, r.direction);
	float lsq = length(l)*length(l);
	float rsq = sp.radius * sp.radius;

	if( s < 0 && lsq > rsq )
		return -1.0f;
	
	float msq = lsq - (s*s);

	if(msq > rsq)
		return -1.0f;

	float q = sqrt(rsq - msq);
	float t = 0.f;
	
	if(lsq > rsq)
	{
		return s - q;		
	}
	else
		return -1.0f;
}

float4 RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2)
{
	float deltaRange = 0.001f;
	float3 e1 = p1 - p0;
	float3 e2 = p2 - p0;
	float3 q = cross(r.direction, e2);
	float a = dot(e1, q);
	if(a > -0.00001 && a < 0.00001)
	{
		return float4(-1.0f,-1.0f,-1.0f,-1.0f);
	}
	float f = 1/a;
	float3 s = r.origin.xyz - p0;
	float u = f*(dot(s,q));
	if(u < 0.f)
	{
		return float4(-1.0f,-1.0f,-1.0f,-1.0f);
	}
	float3 Rr = cross(s, e1);
	float v = f*(dot(r.direction.xyz,Rr));
	if(v < 0.0f || u+v > 1.0f)
	{
		return float4(-1.0f,-1.0f,-1.0f,-1.0f);
	}
	return float4(f*(dot(e2,Rr)),u,v, 1-u-v);
}

float component(float3 f, int i)
{
	switch(i)
	{
		case 0: return f.x;
		case 1: return f.y;
		case 2: return f.z;
		default: return 0.f;
	}
}

bool RayAABB(Ray r, float3 AABBmin, float3 AABBmax)
{	
	//http://prideout.net/blog/?p=64

	//http://pastebin.com/PCmvDFKr
	const float ox=r.origin.x, oy=r.origin.y, oz=r.origin.z;
	const float dx=r.direction.x, dy=r.direction.y, dz=r.direction.z;

	float tx_min, ty_min, tz_min;
	float tx_max, ty_max, tz_max;

	// x
	float a = 1.f/dx;
	if(a >= 0)
	{
		tx_min = (AABBmin.x-ox)*a;
		tx_max = (AABBmax.x-ox)*a;
	}
	else
	{
		tx_min = (AABBmax.x-ox)*a;
		tx_max = (AABBmin.x-ox)*a;
	}

	// y
	float b = 1.f/dy;
	if(b >= 0)
	{
		ty_min = (AABBmin.y-oy)*b;
		ty_max = (AABBmax.y-oy)*b;
	}
	else
	{
		ty_min = (AABBmax.y-oy)*b;
		ty_max = (AABBmin.y-oy)*b;
	}

	// z
	float c = 1.f/dz;
	if(c >= 0)
	{
		tz_min = (AABBmin.z-oz)*c;
		tz_max = (AABBmax.z-oz)*c;
	}
	else
	{
		tz_min = (AABBmax.z-oz)*c;
		tz_max = (AABBmin.z-oz)*c;
	}

	float t0, t1;

	// find largest entering t-value
	t0 = max(tx_min, ty_min);
	t0 = max(tz_min, t0);

	// find smallest exiting t-value
	t1 = min(tx_max, ty_max);
	t1 = min(tz_max, t1);

	if(t0 < t1 && t1 > 0.0001f)
	{
		return true;
	}
	return false;
}
#endif // INTERSECTIONCOMPUTE