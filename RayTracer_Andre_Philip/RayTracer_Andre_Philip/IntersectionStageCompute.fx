#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};
StructuredBuffer<Vertex> Triangles : register(t0);
//StructuredBuffer<OBJVertex> OBJ : register(t1);
//StructuredBuffer<DWORD> Indices : register(t2);
StructuredBuffer<HLSLNode> OctTree : register(t1);
StructuredBuffer<OBJVertex> OctTreeVertices : register(t2);
Texture2D objtexture : register(t3);


RWStructuredBuffer<Ray> IO_Rays : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);


//void recursiveoctTraversal(Ray r, int currentNode, float4 returnT, int triangleIndex);

#define DELTARANGE 0.0001f

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
	int tempID = -1;

	//Sphere collision
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
	}
	increasingID++;

	//Box collision
	volatile float4 returnT4 = float4(0,0,0,0);
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

	float4x4 scale = cd.scale;
	
	if(RayAABB(r,  OctTree[0].boundLow, OctTree[0].boundHigh))
	{
		int stackIndex = 0;
		volatile HLSLNode stack[20];

		stack[++stackIndex] = OctTree[0];
		volatile HLSLNode node;


		int finalTriangle = -1;
		float4 finalTriangleData;

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


//void recursiveoctTraversal(Ray r, int currentNode, float4 returnT, int triangleIndex)
//{
//	HLSLNode curr = OctTree[currentNode];
//	float4x4 scale = cd.scale;
//	for(unsigned int i = 0; i < 8; i++)
//	{
//		//Check if the next node exists
//		if(curr.nodes[i] < 0) break;
//
//		if(RayAABB(r,  OctTree[curr.nodes[i]].boundLow, OctTree[curr.nodes[i]].boundHigh))
//		{
//			int nrVertices = OctTree[curr.nodes[i]].nrVertices;
//
//			//Check if it's a leaf node or not
//			if( nrVertices == 0)
//				recursiveoctTraversal(r, i, returnT, triangleIndex);
//			else
//			{
//				int startTri = OctTree[curr.nodes[i]].startVertexLocation;
//				int endTri = startTri + nrVertices;
//				for(unsigned int tri = startTri; tri < endTri; tri++)
//				{
//					//Avoid selfcollision
//					if(triangleIndex == tri) continue;
//
//					float4 ret = RayTriangleIntersection(r,mul(float4(OBJ[i].position,1), scale).xyz, mul(float4(OBJ[i+1].position,1), scale).xyz, mul(float4(OBJ[i+2].position,1), scale).xyz);
//					//returnT = returnT4.x;
//
//					if(ret.x < returnT.x && ret.x > DELTARANGE || returnT.x < 0.0f && ret.x > DELTARANGE)
//					{
//						returnT = ret;
//						triangleIndex = tri;
//
//						//h.distance = returnT;
//						//uvCoord = returnT4.w*OBJ[i].texCoord + returnT4.y*OBJ[i+1].texCoord +returnT4.z * OBJ[i+2].texCoord;
//						//uvCoord *= 512;
//						//h.materialID = OBJ[i].materialID;
//						//h.color = objtexture[uvCoord];
//						//tempID = increasingID;
//						//h.reflection = 0.0f;//Triangles[i].reflection;
//						//h.normal = OBJ[i].normal;//normalize(cross(Triangles[i+1].position-Triangles[i].position,Triangles[i+2].position-Triangles[i].position));
//					}
//				}
//			}
//		}
//	}
//}

#endif // PRIMARYRAYCOMPUTE