#ifndef COLORSTAGECOMPUTE
#define COLORSTAGECOMPUTE
#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

float3 LightSourceCalc(Ray r, HitData h, PointLight l);

cbuffer cBufferdata : register(b0){cData cd;};

StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<HitData> InputHitdata : register(t1);
StructuredBuffer<PointLight> pl : register(t2);

RWTexture2D<float4> output : register(u0);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);
	HitData h = InputHitdata[index];
	Sphere s;
	s.position = float3(0,0,0);
	s.radius = 5.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;

	if(h.id == -1)
	{
		output[ThreadID.xy] = h.color;
	}
	else
	{
		float4 t = float4(0, 0, 0, 0);
		float4 color = float4(0,0,0,0);
		Ray L;// Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
		L.origin = h.r.origin + (h.r.direction *h.distance);
		HitData shadowh;
		shadowh.color = float4(0,0,0,1);
		shadowh.id = -1;
		shadowh.normal = float3(0,0,0);
		//[unroll] //IF FPS PROBLEM REMOVE THIS
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
				if(h.id != Triangles[j].id)
					shadowh = RayTriangleIntersection(L,Triangles[j].position, Triangles[j+1].position, Triangles[j+2].position,Triangles[j].color, Triangles[j].id, shadowh);
			}
			
			if(shadowh.distance > 0.f && shadowh.distance < lightDistance)
				t += 0.5f * float4(LightSourceCalc(L, h, pl[i]),0.f);	
			else
				t += 1.0f * float4(LightSourceCalc(L, h, pl[i]),0.f);
			
			color += (h.color*float4(0.1f,0.1f,0.1f,1)) * t;
		}

		output[ThreadID.xy] = color;
	}
}

float3 LightSourceCalc(Ray r, HitData h, PointLight l)
{
	//PHONG
	float4 diffuse = { 1.0f, 0.0f, 0.0f, 1.0f};
	diffuse = l.diffuse;
	float4 ambient = { 0.1f, 0.0f, 0.0f, 1.0f};
	ambient = l.ambient;

	float3 Normal = normalize(h.normal);
	float3 LightDir = normalize(l.position.xyz - r.origin);
	float3 ViewDir = -normalize(r.origin - cd.camPos); 
	float4 diff = saturate(dot(Normal, LightDir)); // diffuse component

	// R = 2 * (N.L) * N - L
	float3 Reflect = normalize(2* diff.xyz * h.normal - LightDir); 
	float4 specular = pow(saturate(dot(Reflect, ViewDir)), 20); // R.V^n

	// I = Acolor + Dcolor * N.L + (R.V)n
	return ambient.xyz + diffuse.xyz * diff.xyz + specular.xyz;
}

#endif //COLORSTAGECOMPUTE