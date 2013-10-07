#ifndef INTERSECTIONCOMPUTE
#define INTERSECTIONCOMPUTE
#include "structsCompute.fx"

HitData RaySphereIntersect(Ray r, Sphere sp, HitData h)
{
	HitData lh;
	lh.id = sp.id;
	float3 l = sp.position - r.origin;
	float s = dot(l, r.direction);
	float lsq = length(l)*length(l);
	float rsq = sp.radius * sp.radius;

	if( s < 0 && lsq > rsq )
		return h;
	
	float msq = lsq - (s*s);

	if(msq > rsq)
		return h;

	float q = sqrt(rsq - msq);
	float t = 0.f;

	//if(lsq > rsq)
	if( s-q > 0.f )
		t = s - q;
	else
		t = s + q;
	
	
	lh.distance = t;
	lh.normal = normalize(r.origin + t*r.direction - sp.position);
	lh.color = sp.color;
	if(lh.distance < h.distance && lh.distance > 0.f)
		return lh;
	else
		return h;
}

HitData RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2, int id, HitData h)
{
	HitData lh;
	lh.id = id;
	float3 e1 = p1 - p0;
	float3 e2 = p2 - p0;
	float3 q = cross(r.direction, e2);
	float a = dot(e1, q);
	if(a > -0.00001 && a < 0.00001)
	{
		return h;
	}
	float f = 1/a;
	float3 s = r.origin - p0;
	float u = f*(dot(s,q));
	if(u < 0.f)
	{
		return h;
	}
	float3 Rr = cross(s, e1);
	float v = f*(dot(r.direction,Rr));
	if(v < 0.0f || u+v > 1.0f)
	{
		return h;
	}
	lh.distance = f*(dot(e2,Rr));
	lh.color = float3(0,1,0);
	float3 v1,v2;
	v1 = p1-p0;
	v2 = p2-p0;
	lh.normal = normalize(cross(v1,v2));

	if(lh.distance < h.distance && lh.distance > 0.f)
		return lh;
	else
		return h;
}

#endif // INTERSECTIONCOMPUTE