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
	r = CreateRay(threadID, screenWidth, screenHeight, camPos, projMatInv, viewMatInv);

	// ########## INTERSECTION STAGE #########
	h = RaySphereIntersect(r, s, h);
	int i;
	for(i = 0; i < 36; i+=3)
	{
		h = RayTriangleIntersection(r,triangles[i].position, triangles[i+1].position, triangles[i+2].position,triangles[i].color ,triangles[i].id, h);
	}
	

	if(h.id == -1)
	{
		output[threadID.xy] = h.color;
	}
	else
	{
		float4 t = float4(0, 0, 0, 0);
		float4 color = float4(0,0,0,0);
		Ray L;// Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
		L.origin = r.origin + (r.direction *h.distance);
		HitData shadowh;
		shadowh.color = float4(0,0,0,1);
		shadowh.id = -1;
		shadowh.normal = float3(0,0,0);

		for(int i = 0; i < 10;i++)
		{
			//NULLIFY
			t = float4(0, 0, 0, 0);			
			shadowh.distance = -1.f;
			shadowh.id = -1;
			//RECALCULATE
			float lightDistance = length(pl[i].position.xyz - L.origin);
			L.direction = normalize(pl[i].position.xyz - L.origin);

			if(h.id != s.id)
				shadowh = RaySphereIntersect(L, s, shadowh);
			
			for(int j = 0; j < 36; j+=3)
			{
				if(h.id != triangles[j].id)
					shadowh = RayTriangleIntersection(L,triangles[j].position, triangles[j+1].position, triangles[j+2].position,triangles[j].color, triangles[j].id, shadowh);
			}
			
			if(shadowh.distance > 0.f && shadowh.distance < lightDistance)
				t += 0.8f * float4(LightSourceCalc(L, h, pl[i]),0.f);	
			else
				t += 1.f * float4(LightSourceCalc(L, h, pl[i]),0.f);
			
			color += h.color * t;
		}

		output[threadID.xy] = color;
	}
}

float3 LightSourceCalc(Ray r, HitData h, PointLight l)
{
	float3 litColor = float3(0.0f, 0.0f, 0.0f);
	
	// The vector from the surface to the light.
	float3 lightVec = l.position.xyz - r.origin ;
		
	// The distance from surface to light.
	float d = length(lightVec);
	
	/*if( d > L.range )
		return float3(0.0f, 0.0f, 0.0f);*/
		
	// Normalize the light vector.
	lightVec /= d;
	
	// Add the ambient light term.
	litColor += h.color.xyz * l.ambient.xyz;	
	
	// Add diffuse and specular term, provided the surface is in 
	// the line of site of the light.
	
	float diffuseFactor = dot(lightVec, h.normal);
	//return float4(1, 1, 1, 1) * diffuseFactor;
	[branch]
	if( diffuseFactor > 0.0f )
	{
		float specPower  = max(h.color.a, 1.0f);
		float3 toEye     = normalize(camPos - r.origin);
		float3 R         = reflect(-lightVec, h.normal);
		float specFactor = pow(max(dot(R, toEye), 0.0f), specPower);
	
		// diffuse and specular terms
		litColor += diffuseFactor * h.color.xyz * l.diffuse.xyz;
		//litColor += specFactor * l.specular;// * v.spec;
	}
	
	// attenuate
	return litColor / dot(l.att.xyz, float3(1.0f, d, d*d));
}