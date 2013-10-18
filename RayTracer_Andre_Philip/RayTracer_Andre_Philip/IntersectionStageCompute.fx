#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};
StructuredBuffer<Vertex> Triangles : register(t0);

RWStructuredBuffer<Ray> IO_Rays : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);

	Sphere s;
	s.position = float3(0,0,0);
	s.radius = 5.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;
	s.reflection = .5f;

	Ray r = IO_Rays[index];

	HitData h;
	h.color = float4(0,0,0,1);
	h.distance = -1.0f;
	h.normal = float3(0,0,0);
	h.r.origin = r.origin;
	h.r.direction = r.direction;
	h.r.power = r.power;
	h.reflection = 0.0f;
	h.id = -1;

	if(cd.firstPass)// && OutputHitdata[index].id != -1)		
		h.id = -1;
	else
		h.id = OutputHitdata[index].id;
	
	float deltaRange = 0.001f;
	float returnT = -1.0f;
	int tempID = -1;

	if(h.id != s.id)
	{
		returnT = RaySphereIntersect(r, s);
		if(returnT < h.distance || h.distance < 0.0f && returnT > deltaRange)
		{
			h.distance = returnT;
			h.color = s.color;
			tempID = s.id;
			h.reflection = s.reflection;
			h.normal = normalize(r.origin + returnT*r.direction - s.position);
		}
	}
	
	for(int i = 0; i < 36; i+=3)
	{
		if(h.id != Triangles[i].id)
		{
			returnT = RayTriangleIntersection(r,Triangles[i].position, Triangles[i+1].position, Triangles[i+2].position);

			if(returnT < h.distance && returnT > 0.f || h.distance < 0.0f && returnT > 0.f)
			{
				h.distance = returnT;
				h.color = Triangles[i].color;
				tempID = Triangles[i].id;
				h.reflection = Triangles[i].reflection;
				h.normal = normalize(cross(Triangles[i+1].position-Triangles[i].position,Triangles[i+2].position-Triangles[i].position));
			}
		}
	}
	if(tempID != -1)
		h.id = tempID;
	
	//h.color = float4(1,0,0,1);

	OutputHitdata[index] = h;

	if(h.id != -1)
	{
		r.origin = r.origin + r.direction * h.distance;
		r.direction = reflect(r.direction, h.normal);	
		r.power = h.reflection;
		//r.id = h.id;
		IO_Rays[index] = r;
	}
}
#endif // PRIMARYRAYCOMPUTE