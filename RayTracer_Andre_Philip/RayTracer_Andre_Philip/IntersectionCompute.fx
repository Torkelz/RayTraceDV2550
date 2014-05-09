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
	float3 invR = 1.0 / r.direction;
	float3 tbot = invR * (AABBmin - r.origin);
	float3 ttop = invR * (AABBmax - r.origin);
	float3 tmin = min(ttop, tbot);
	float3 tmax = max(ttop, tbot);
	float2 t = max(tmin.xx, tmin.yz);

	float t0 = max(t.x, t.y);
	t = min(tmax.xx, tmax.yz);
	float t1 = min(t.x, t.y);
	return t0 <= t1;


	//Real-Time Collision Detection

	//float tmin = 0.0f;
	//float tmax = 3000000000.f;
	//bool r77 = true;
	//[allow_uav_condition]
	//for(int i = 0; i < 3;i++)
	//{
	//	float origin = component(r.origin, i);
	//	float dir = component(r.direction, i);
	//	float bmin = component(AABBmin, i);
	//	float bmax = component(AABBmax, i);
	//	if(abs(dir) < 0.0001f)
	//	{
	//		if(origin < bmin || origin > bmax)
	//		{
	//			return false;//r77 = false;
	//		}
	//	}
	//	else
	//	{
	//		 Compute intersection t value of ray with near and far plane of slab
	//		float ood = 1.0f / dir;
	//		float t1 = (bmin - origin) * ood;
	//		float t2 = (bmax - origin) * ood;
	//		 Make t1 be intersection with near plane, t2 with far plane
	//		if (t1 > t2)
	//		{
	//			float temp = t1;
	//			t1 = t2;
	//			t2 = temp;
	//		}
	//		 Compute the intersection of slab intersection intervals
	//		if (t1 > tmin) tmin = t1;
	//		if (t2 > tmax) tmax = t2;
	//		 Exit with no collision as soon as slab intersection becomes empty
	//		if (tmin > tmax) return false;//r77 = false;
	//	}
	//}
	//return true;
}
#endif // INTERSECTIONCOMPUTE