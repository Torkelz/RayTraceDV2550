#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};
//StructuredBuffer<Ray> InputRays : register(t0);
StructuredBuffer<Vertex> Triangles : register(t0);

RWStructuredBuffer<Ray> IO_Rays : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);


[numthreads(32, 32, 1)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);

	Sphere s;
	s.position = float3(0,0,0);
	s.radius = 5.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;

	Ray r = IO_Rays[index];

	HitData h;
	h.color = float4(0,0,0,1);
	h.distance = -1.0f;
	h.normal = float3(0,0,0);
	h.r = r;
	h.id = -1;

	h = RaySphereIntersect(r, s, h);
	
	for(int i = 0; i < 36; i+=3)
	{
		h = RayTriangleIntersection(r,Triangles[i].position, Triangles[i+1].position, Triangles[i+2].position,Triangles[i].color ,Triangles[i].id, h);
	}
	h.color = float4(1,0,0,1);

	OutputHitdata[index] = h;
	if(h.id != -1)
	{
		r.origin = r.origin + r.direction * h.distance;
		r.direction = reflect(r.direction, h.normal);		
		IO_Rays[index] = r;
	}
}
#endif // PRIMARYRAYCOMPUTE