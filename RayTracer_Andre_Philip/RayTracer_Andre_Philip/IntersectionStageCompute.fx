#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};

StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<HLSLNode> OctTree : register(t1);
StructuredBuffer<OBJVertex> OctTreeVertices : register(t2);
Texture2D objtexture : register(t3);

RWStructuredBuffer<Ray> IO_Rays : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);

	uint dimension;
	uint stride;
	OctTreeVertices.GetDimensions(dimension, stride);
	int increasingID = dimension;

	//Creates a sphere
	Sphere s;
	s.position = float3(-13,10,0);
	s.radius = 2.f;
	s.color = float4(0.9,0,0,1);
	s.reflection = 1.f;

	Ray r = IO_Rays[index];

	//Sets default HitData values
	volatile HitData h;
	h.color = float4(0,0,0,1);
	h.distance = -1.0f;
	h.normal = float3(0,0,0);
	h.r.origin = r.origin;
	h.r.direction = r.direction;
	h.r.power = r.power;
	h.reflection = 0.0f;
	h.id = OutputHitdata[index].id;
	h.materialID = -1;

	const float deltaRange = 0.0001f;
	volatile float returnT = -1.0f;
	volatile int tempID = -1;

	//Sphere collision
	if( h.id != increasingID)
	{
		returnT = RaySphereIntersect(r, s);
		if(returnT < h.distance || h.distance < 0.0f && returnT > deltaRange)
		{
			h.distance = returnT;
			h.color = s.color;
			tempID = increasingID;
			h.reflection = s.reflection;
			h.normal = normalize(r.origin + returnT*r.direction - s.position);
		}
	}
	increasingID++;

	//Box collision
	volatile float4 returnT4 = float4(0,0,0,0);
	for(int i = 0; i < 36; i+=3)
	{
		if( h.id != increasingID)
		{
			returnT4 = RayTriangleIntersection(r,Triangles[i].position, Triangles[i+1].position, Triangles[i+2].position);
			returnT = returnT4.x;
			if(returnT < h.distance && returnT > deltaRange || h.distance < 0.0f && returnT > deltaRange)
			{
				h.distance = returnT;
				h.color = Triangles[i].color;
				tempID = increasingID;
				h.reflection = Triangles[i].reflection;
				h.normal = normalize(cross(Triangles[i+1].position-Triangles[i].position,Triangles[i+2].position-Triangles[i].position));
			}
		}
		increasingID++;
	}

	float4x4 scale = cd.scale;
	
	//Check if root in octTree is hit
	if(RayAABB(r,  OctTree[0].boundLow, OctTree[0].boundHigh))
	{
		int stackIndex = 0;
		volatile HLSLNode stack[20];

		stack[++stackIndex] = OctTree[0];
		volatile HLSLNode node;


		int finalTriangle = -1;
		float4 finalTriangleData;

		//depth-first search
		[allow_uav_condition]
		while(stackIndex > 0)
		{
			node = stack[stackIndex--];

			if(node.nrVertices > 0)
			{
				int startTri = node.startVertexLocation;
				[allow_uav_condition]
				for(int tri = 0; tri < node.nrVertices; tri++)
				{
					int vertexIndex = startTri + (tri * 3);
					//Avoid selfcollision
					if(h.id == vertexIndex) continue;

					returnT4 = RayTriangleIntersection(r,mul(float4(OctTreeVertices[vertexIndex].position,1), scale).xyz, 
						mul(float4(OctTreeVertices[vertexIndex + 1].position,1), scale).xyz, 
						mul(float4(OctTreeVertices[vertexIndex + 2].position,1), scale).xyz);

					returnT = returnT4.x;

					if(returnT < h.distance && returnT > deltaRange || h.distance < 0.0f && returnT > deltaRange)
					{
						h.distance = returnT;
						finalTriangle = vertexIndex;
						finalTriangleData = returnT4;
					}
				}
			}
			//[allow_uav_condition]
			for(int i = 0; i < 8; i++)
			{
				if(node.nodes[i] > 0)
				{
					if(RayAABB(r,  OctTree[node.nodes[i]].boundLow, OctTree[node.nodes[i]].boundHigh))
					{
						stack[++stackIndex] = OctTree[node.nodes[i]];
					}
				}
			}
		}

		//If a triangle was intersected set hitdata
		if(finalTriangle >= 0)
		{
			float2 uvCoord = finalTriangleData.w * OctTreeVertices[finalTriangle].texCoord + 
				finalTriangleData.y * OctTreeVertices[finalTriangle + 1].texCoord +
				finalTriangleData.z * OctTreeVertices[finalTriangle + 2].texCoord;
			uvCoord *= 512;
			h.materialID = OctTreeVertices[finalTriangle].materialID;
			h.color = objtexture[uvCoord];
			tempID = increasingID;
			h.reflection = 0.0f;
			h.normal = OctTreeVertices[finalTriangle].normal;

			tempID = finalTriangle;
		}
	}

	if(tempID != -1)//h.id != -1)
	{
		h.id = tempID;
		r.origin = r.origin + r.direction * h.distance;
		r.direction = reflect(r.direction, h.normal);
		if(r.power != 0.0f)
			r.power = h.reflection;
		//r.id = h.id;
		IO_Rays[index] = r;
	} 

	OutputHitdata[index] = h;
}
#endif // PRIMARYRAYCOMPUTE