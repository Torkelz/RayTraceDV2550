#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};
StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<OBJVertex> OBJ : register(t1);
StructuredBuffer<DWORD> Indices : register(t2);

Texture2D objtexture : register(t3);

RWStructuredBuffer<Ray> IO_Rays : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);
	int increasingID = 0;

	Sphere s;
	s.position = float3(-13,10,0);
	s.radius = 2.f;
	s.color = float4(0.9,0,0,1);
	s.reflection = 1.f;

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
	h.materialID = -1;

	if(cd.firstPass)// && OutputHitdata[index].id != -1)		
		h.id = -1;
	else
		h.id = OutputHitdata[index].id;
	
	float deltaRange = 0.0001f;
	float returnT = -1.0f;
	int tempID = -1;

	//if(h.id != s.id)
	
	if( h.id != increasingID)
	{
		returnT = RaySphereIntersect(r, s);
		if(returnT < h.distance || h.distance < 0.0f && returnT > deltaRange)
		{
			h.distance = returnT;
			h.color = s.color;
			//tempID = s.id;
			tempID = increasingID;
			h.reflection = s.reflection;
			h.normal = normalize(r.origin + returnT*r.direction - s.position);
		}
		increasingID++;
	}
	float4 returnT4 = float4(0,0,0,0);
	for(int i = 0; i < 36; i+=3)
	{
		//if(h.id != Triangles[i].id)
		if( h.id != increasingID)
		{
			returnT4 = RayTriangleIntersection(r,Triangles[i].position, Triangles[i+1].position, Triangles[i+2].position);
			returnT = returnT4.x;
			if(returnT < h.distance && returnT > deltaRange || h.distance < 0.0f && returnT > deltaRange)
			{
				h.distance = returnT;
				h.color = Triangles[i].color;
				//tempID = Triangles[i].id;
				tempID = increasingID;
				h.reflection = Triangles[i].reflection;
				h.normal = normalize(cross(Triangles[i+1].position-Triangles[i].position,Triangles[i+2].position-Triangles[i].position));
			}
		}
		increasingID++;
	}
	//[unroll(100)]
	int numV = cd.nrVertices;
	float4x4 scale = cd.scale;
	float2 uvCoord ;
			
	for(int i = 0; i < numV; i+=3)
	{
		//if(h.id != Triangles[i].id)
		if( h.id != increasingID)
		{
			returnT4 = RayTriangleIntersection(r,mul(float4(OBJ[i].position,1), scale).xyz, mul(float4(OBJ[i+1].position,1), scale).xyz, mul(float4(OBJ[i+2].position,1), scale).xyz);
			returnT = returnT4.x;

			if(returnT < h.distance && returnT > deltaRange || h.distance < 0.0f && returnT > deltaRange)
			{
				h.distance = returnT;
				uvCoord = returnT4.w*OBJ[i].texCoord + returnT4.y*OBJ[i+1].texCoord +returnT4.z * OBJ[i+2].texCoord;
				uvCoord *= 512;
				h.materialID = OBJ[i].materialID;
				h.color = objtexture[uvCoord];
				tempID = increasingID;
				h.reflection = 0.0f;//Triangles[i].reflection;
				h.normal = OBJ[i].normal;//normalize(cross(Triangles[i+1].position-Triangles[i].position,Triangles[i+2].position-Triangles[i].position));
			}
		}
		increasingID++;
	}


	if(tempID != -1)
		h.id = tempID;

	//h.color = float4(1,0,0,1);

	OutputHitdata[index] = h;

	if(h.id != -1)
	{
		r.origin = r.origin + r.direction * h.distance;
		r.direction = reflect(r.direction, h.normal);
		if(r.power != 0.0f)
			r.power = h.reflection;
		//r.id = h.id;
		IO_Rays[index] = r;
	} 
	
}
#endif // PRIMARYRAYCOMPUTE