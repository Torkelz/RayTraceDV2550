//--------------------------------------------------------------------------------------
// BasicCompute.fx
// Direct3D 11 Shader Model 5.0 Demo
// Copyright (c) Stefan Petersson, 2012
//--------------------------------------------------------------------------------------
#pragma pack_matrix(row_major)
#include "PrimaryCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};

RWTexture2D<float4> output : register(u0);
StructuredBuffer<Vertex> triangles : register(t0);
StructuredBuffer<PointLight> pl : register(t1);

StructuredBuffer<HitData> InputRays : register(t2);

//Methods
float3 LightSourceCalc(Ray r, HitData h, PointLight l);

groupshared Sphere s;
[numthreads(32, 32, 1)]
void main( uint3 threadID : SV_DispatchThreadID,
		  uint groupID : SV_GroupIndex)
{
	//if(groupID == 0)
	//{
		s.position = float3(0,0,0);
		s.radius = 5.f;
		s.color = float4(0.9,0,0,1);
		s.id = 0;

		HitData h;
		h.color = float4(0,0,0,1);
		h.distance = -1.0f;
		h.normal = float3(0,0,0);
		h.id = -1;
	//}
	//GroupMemoryBarrierWithGroupSync();

	// ########## PRIMARY STAGE ###########
	Ray r;
	r = CreateRay(threadID, cd.screenWidth, cd.screenHeight, cd.camPos, cd.projMatInv, cd.viewMatInv);
	//r = InputRays[threadID.x+(threadID.y*cd.screenWidth)];

	// ########## INTERSECTION STAGE #########
	h = RaySphereIntersect(r, s, h);
	int i;
	
	for(i = 0; i < 36; i+=3)
	{
		h = RayTriangleIntersection(r,triangles[i].position, triangles[i+1].position, triangles[i+2].position,triangles[i].color ,triangles[i].id, h);
	}
	
	h = InputRays[threadID.x+(threadID.y*cd.screenWidth)];
	output[threadID.xy] = h.color;
	//if(h.id == -1)
	//{
	//	output[threadID.xy] = h.color;
	//}
	//else
	//{
	//	float4 t = float4(0, 0, 0, 0);
	//	float4 color = float4(0,0,0,0);
	//	Ray L;// Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
	//	L.origin = r.origin + (r.direction *h.distance);
	//	HitData shadowh;
	//	shadowh.color = float4(0,0,0,1);
	//	shadowh.id = -1;
	//	shadowh.normal = float3(0,0,0);
	//	//[unroll] //IF FPS PROBLEM REMOVE THIS
	//	for(int i = 0; i < 10;i++)
	//	{
	//		//NULLIFY
	//		t = float4(0, 0, 0, 0);			
	//		shadowh.distance = -1.f;
	//		shadowh.id = -1;
	//		//RECALCULATE
	//		float lightDistance = length(pl[i].position.xyz - L.origin);
	//		L.direction = normalize(pl[i].position.xyz - L.origin);

	//		if(h.id != s.id)
	//			shadowh = RaySphereIntersect(L, s, shadowh);
	//		
	//		for(int j = 0; j < 36; j+=3)
	//		{
	//			if(h.id != triangles[j].id)
	//				shadowh = RayTriangleIntersection(L,triangles[j].position, triangles[j+1].position, triangles[j+2].position,triangles[j].color, triangles[j].id, shadowh);
	//		}
	//		
	//		if(shadowh.distance > 0.f && shadowh.distance < lightDistance)
	//			t += 0.5f * float4(LightSourceCalc(L, h, pl[i]),0.f);	
	//		else
	//			t += 1.0f * float4(LightSourceCalc(L, h, pl[i]),0.f);
	//		
	//		color += (h.color*float4(0.1f,0.1f,0.1f,1)) * t;
	//	}

	//	output[threadID.xy] = color;
	//}
}

float3 LightSourceCalc(Ray r, HitData h, PointLight l)
{
	//PHONG

	float4 diffuse = { 1.0f, 0.0f, 0.0f, 1.0f};
	diffuse = l.diffuse;
	float4 ambient = { 0.1f, 0.0f, 0.0f, 1.0f};
	ambient = l.ambient;

	float3 Normal = normalize(h.normal);
	float3 LightDir = normalize(l.position - r.origin);
	float3 ViewDir = -normalize(r.origin - cd.camPos); 
	float4 diff = saturate(dot(Normal, LightDir)); // diffuse component

	// R = 2 * (N.L) * N - L
	float3 Reflect = normalize(2* diff * h.normal - LightDir); 
	float4 specular = pow(saturate(dot(Reflect, ViewDir)), 20); // R.V^n

	// I = Acolor + Dcolor * N.L + (R.V)n
	return ambient + diffuse * diff + specular;
}