#ifndef INTERSECTIONCOMPUTE
#define INTERSECTIONCOMPUTE
#include "structsCompute.fx"

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

float RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2)
{
	float deltaRange = 0.001f;
	float3 e1 = p1 - p0;
	float3 e2 = p2 - p0;
	float3 q = cross(r.direction, e2);
	float a = dot(e1, q);
	if(a > -0.00001 && a < 0.00001)
	{
		return -1.0f;
	}
	float f = 1/a;
	float3 s = r.origin.xyz - p0;
	float u = f*(dot(s,q));
	if(u < 0.f)
	{
		return -1.0f;
	}
	float3 Rr = cross(s, e1);
	float v = f*(dot(r.direction.xyz,Rr));
	if(v < 0.0f || u+v > 1.0f)
	{
		return -1.0f;
	}
	return f*(dot(e2,Rr));
}
#endif // INTERSECTIONCOMPUTE