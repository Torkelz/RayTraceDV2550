//--------------------------------------------------------------------------------------
// BasicCompute.fx
// Direct3D 11 Shader Model 5.0 Demo
// Copyright (c) Stefan Petersson, 2012
//--------------------------------------------------------------------------------------
#pragma pack_matrix(row_major)

struct Sphere
{
	float3 position;
	float3 color;
	float  radius;
};

struct Vertex
{
	float3 position;
	float3 color;
	//More to come!!
};

struct HitData
{
	float3 color;
	float distance;
	float3 normal;
};

struct PointLight
{
	float3 position;
	float4 color;
	float4 diffuse;
	float4 ambient;
};

cbuffer cBufferdata : register(c0)
{
	matrix		viewMatInv;
	matrix		projMatInv;
	float4x4	WVP;
	float3		camPos;
	int			screenWidth;
	int			screenHeight;
	float		fovX;
	float		fovY;
};

struct Ray
{
	float3 origin;
	float3 direction;
};
RWTexture2D<float4> output : register(u0);
StructuredBuffer<Vertex> triangles : register(t0);
//Methods
float4 LightSourceCalc(Ray r, HitData h, PointLight l);
HitData RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2, HitData h);
HitData RaySphereIntersect(Ray r, Sphere s, HitData h);

groupshared Sphere s;
groupshared PointLight pl;
[numthreads(32, 32, 1)]
void main( uint3 threadID : SV_DispatchThreadID,
		  uint groupID : SV_GroupIndex)
{
	//if(groupID == 0)
	//{
		s.position = float3(0,0,0);
		s.radius = 5.f;
		s.color = float3(1,0,0);

		pl.position = float3(0,10,-10);
		pl.color	= float4(1,1,1,1);
		pl.diffuse	= float4(1,1,1,1);
		pl.ambient	= float4(0.0f,0,0,1);

		HitData h;
		h.color = float3(0,0,0);
		h.distance = 1000.0f;
		h.normal = float3(0,0,0);
	//}
	//GroupMemoryBarrierWithGroupSync();
	Ray r;
	r.origin = camPos;

	float screenSpaceX = ((((float)threadID.x/screenWidth)  *2) - 1.0f);
	float screenSpaceY = (((1.0f -((float)threadID.y/screenHeight)) * 2) - 1.0f);

	float4 screenPoint = float4(screenSpaceX, screenSpaceY, 1,1);
	screenPoint = mul(screenPoint, projMatInv);

	screenPoint /= screenPoint.w;
	screenPoint = mul(screenPoint, viewMatInv);

	float3 dir = screenPoint.xyz - camPos;
	dir = normalize(dir);

	r.direction = dir;
	//dir.z = 0.0f;

	h = RaySphereIntersect(r, s, h);
	int i;
	for(i = 0; i < 6; i+=3)
	{
		h = RayTriangleIntersection(r,triangles[i].position, triangles[i+1].position, triangles[i+2].position, h);
	}

	//h = RayTriangleIntersection(r,float3(-5,-5,0), float3(-5,5,0), float3(5,-5,0));
	

	output[threadID.xy] = float4(dir,1);
	if(h.distance < 0)
		output[threadID.xy] = float4(h.color,1);
	else
		output[threadID.xy] = float4(h.color,1) * LightSourceCalc(r, h, pl);
}

HitData RaySphereIntersect(Ray r, Sphere sp, HitData h)
{
	HitData lh;

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

	if(lsq > rsq)
		t = s - q;
	else
		t = s + q;
	
	lh.color = sp.color;
	lh.distance = t;
	lh.normal = normalize(r.origin + t*r.direction - sp.position);

	if(lh.distance < h.distance && lh.distance > 0.f)
		return lh;
	else
		return h;
}

HitData RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2, HitData h)
{
	HitData lh;
	
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

float4 LightSourceCalc(Ray r, HitData h, PointLight l)
{
	float3 objectPos = r.origin + r.direction * h.distance;
	float3 sNormal = normalize( h.normal );
	float3 lightDir = -normalize(objectPos - l.position);
	float3 view = normalize(r.direction);
	float4 diff = saturate(dot(sNormal, lightDir));

	float3 reflect = normalize (2.0f*diff*sNormal-lightDir);
	float4 specular = pow(saturate(dot(reflect, view)),10);
	

	return l.ambient + l.diffuse * diff + specular;
}