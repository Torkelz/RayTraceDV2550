//--------------------------------------------------------------------------------------
// BasicCompute.fx
// Direct3D 11 Shader Model 5.0 Demo
// Copyright (c) Stefan Petersson, 2012
//--------------------------------------------------------------------------------------
#pragma pack_matrix(row_major)
#include "PrimaryCompute.fx"
#include "IntersectionCompute.fx"

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

RWTexture2D<float4> output : register(u0);
StructuredBuffer<Vertex> triangles : register(t0);
StructuredBuffer<PointLight> pl : register(t1);

//Methods
float4 LightSourceCalc(Ray r, HitData h, PointLight l);

groupshared Sphere s;
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
	r = CreateRay(threadID, screenWidth, screenHeight, camPos, projMatInv, viewMatInv);

	h = RaySphereIntersect(r, s, h);
	int i;
	for(i = 0; i < 6; i+=3)
	{
		h = RayTriangleIntersection(r,triangles[i].position, triangles[i+1].position, triangles[i+2].position, triangles[i].id, h);
	}
	
	if(h.id == -1)
		output[threadID.xy] = float4(h.color,1);
	else
	{
		//Ray L; Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
		r.origin = r.origin + (r.direction *h.distance) + (h.normal * delta);
		HitData shadowh;
		shadowh.color = float3(0,0,0);
		shadowh.distance = 1000.0f;
		shadowh.normal = float3(0,0,0);
		shadowh.id = -1;
		
		float4 t;
		//t = float4(0.5,0.5,0.5,0.5);
		int ps = 1;
		for(int i = ps-1; i < ps+3;i++)
		{
			r.direction = normalize(pl[i].position - r.origin);

			float distanceToLight = length(pl[i].position - r.origin);

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
		output[threadID.xy] = float4(h.color,1) * t;
	}
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