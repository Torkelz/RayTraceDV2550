#ifndef FILLSLBVH
#define FILLSLBVH

#pragma pack_matrix(row_major)
#include "structsCompute.fx"

cbuffer cBufferdata : register(b0){cData cd;};
StructuredBuffer<OBJVertex> Primitives : register(t0);

RWStructuredBuffer<MortonCode> outputMorton : register(u0);

[numthreads(1, 1, 1)]
void main( uint3 DTid : SV_DispatchThreadID )
{
	float3 bbMin = (3*cd.boundingVMin);
	float3 bbMax = (3*cd.boundingVMax);
	int index = DTid.x + (DTid.y*cd.groups);

	//Adjust to the size of the grid 1024
	float3 invBox = 1024.0f / (bbMin-bbMax);

	int3 primComp = int3((Primitives[index].position - bbMin)* invBox);
	uint zComp = (primComp.z & 1);
	uint yComp = ((primComp.y & 1) << 1);
	uint xComp = ((primComp.x & 1) << 2);

	//Create Morton code
	uint mCode = zComp | yComp | xComp;

	int shift3 = 2;
	int shift = 2;
	int3 temp = int3(Primitives[index].position);

	//30 bit Morton code
	for(int i = 0; i < 10; i++)
	{
		mCode |= (temp.z & shift) << (shift3++);
		mCode |= (temp.y & shift) << (shift3++);
		mCode |= (temp.x & shift) << shift3;
		shift <<= 1;
	}
	outputMorton[index].primitiveID = index;
	outputMorton[index].code = mCode;

}
#endif // FILLSLBVH