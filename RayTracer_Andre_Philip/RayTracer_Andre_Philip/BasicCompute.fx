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
	int id;
};

struct Vertex
{
	float3 position;
	float3 color;
	int id;
	//More to come!!
};

struct HitData
{
	float3 color;
	float distance;
	float3 normal;
	int	id;
};

struct PointLight
{
	float3 position;
	float4 color;
	float4 diffuse;
	float4 ambient;
	float4 specular;
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
StructuredBuffer<PointLight> pl : register(t1);

//Methods
float4 LightSourceCalc(Ray r, HitData h, PointLight l);
HitData RayTriangleIntersection(Ray r, float3 p0, float3 p1, float3 p2, int id, HitData h);
HitData RaySphereIntersect(Ray r, Sphere s, HitData h);

groupshared Sphere s;
//groupshared PointLight pl;
[numthreads(32, 32, 1)]
void main( uint3 threadID : SV_DispatchThreadID,
		  uint groupID : SV_GroupIndex)
{
	float delta = 0.001f; //Moving the collision point a little bit out  from the object.
	//if(groupID == 0)
	//{
		s.position = float3(0,0,0);
		s.radius = 5.f;
		s.color = float3(1,0,0);
		s.id = 0;

		HitData h;
		h.color = float3(0,0,0);
		h.distance = 1000.0f;
		h.normal = float3(0,0,0);
		h.id = -1;
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
		h = RayTriangleIntersection(r,triangles[i].position, triangles[i+1].position, triangles[i+2].position, triangles[i].id, h);
	}

	//h = RayTriangleIntersection(r,float3(-5,-5,0), float3(-5,5,0), float3(5,-5,0));
	

	if(h.id == -1)
		output[threadID.xy] = float4(h.color,1);
	else
	{
//		Ray L; Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
		r.origin = r.origin + (r.direction *h.distance) + (h.normal * delta);
		HitData shadowh;
		shadowh.color = float3(0,0,0);
		shadowh.distance = 1000.0f;
		shadowh.normal = float3(0,0,0);
		shadowh.id = -1;
		
		//L.origin = r.origin + r.direction * h.distance;
		
		float4 t;
		//t = float4(0.5,0.5,0.5,0.5);
		int ps = 1;
		for(int i = ps-1; i < ps+3;i++)
		{
			r.direction = normalize(pl[i].position - r.origin);

			float distanceToLight = length(pl[i].position - r.origin);
			////HitData h;
			//hh.distance = 1000.0f;

			shadowh = RaySphereIntersect(r, s, shadowh);

			int j;
			for(j = 0; j < 6; j+=3)
			{
				shadowh = RayTriangleIntersection(r,triangles[j].position, triangles[j+1].position, triangles[j+2].position, triangles[j].id, shadowh);
			}
			
			//if(h.id != hh.id )//&& hh.id == -1)
			if(shadowh.id == -1 || distanceToLight < shadowh.distance)
				t +=  float4(0.1,0.1,0.1,0.1);//LightSourceCalc(r, h, pl[i]);
		}
		
		//t =  LightSourceCalc(r, h, pl[9]);
		output[threadID.xy] = float4(h.color,1) * t;
	}
}

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

float4 LightSourceCalc(Ray r, HitData h, PointLight l)
{
	float3 lightDir = normalize(r.origin + r.direction*h.distance - l.position);
	float3 objectPos = r.origin + r.direction*h.distance;
	// Note: Non-uniform scaling not supported
	float diffuseLighting = saturate(dot(h.normal, -lightDir)); // per pixel diffuse lighting
	float LightDistanceSquared = pow(length(l.position - objectPos),2);
	// Introduce fall-off of light intensity
	diffuseLighting *= (LightDistanceSquared / dot(l.position - objectPos, l.position - objectPos));
 
	// Using Blinn half angle modification for perofrmance over correctness
	float3 hk = normalize(normalize(r.origin - objectPos) - lightDir);
 
	float specLighting = pow(saturate(dot(hk, h.normal)), l.specular);
 
	return float4(saturate(l.ambient +(l.diffuse * diffuseLighting * 0.6) + (l.specular * specLighting * 0.5)));
}