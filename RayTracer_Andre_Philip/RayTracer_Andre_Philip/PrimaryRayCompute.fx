#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"

Ray CreateRay(uint3 thread, int screenWidth, int screenHeight, float3 camPos, matrix projMatInv, matrix viewMatInv);

cbuffer cBufferdata : register(b0){cData cd;};

RWStructuredBuffer<Ray> outputRay : register(u0);
RWStructuredBuffer<HitData> OutputHitdata : register(u1);
RWTexture2D<float4> output : register(u2);
RWStructuredBuffer<float4> accOutput : register(u3);


[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	uint index = ThreadID.x + (ThreadID.y*cd.screenWidth);
	outputRay[index] = CreateRay(ThreadID, cd.screenWidth, cd.screenHeight, cd.camPos, cd.projMatInv, cd.viewMatInv);

	//Sets data to default values
	OutputHitdata[index].id = -1;
	accOutput[index] = float4(0,0,0,0);
	output[ThreadID.xy] = float4(0,0,0,1);
}

Ray CreateRay(uint3 thread, int screenWidth, int screenHeight, float3 camPos, matrix projMatInv, matrix viewMatInv)
{
	Ray r;
	r.origin = camPos;

	float screenSpaceX = ((((float)thread.x/screenWidth)  *2) - 1.0f);
	float screenSpaceY = (((1.0f -((float)thread.y/screenHeight)) * 2) - 1.0f);

	float4 screenPoint = float4(screenSpaceX, screenSpaceY, 1,1);
	screenPoint = mul(screenPoint, projMatInv);

	screenPoint /= screenPoint.w;
	screenPoint = mul(screenPoint, viewMatInv);

	float3 dir = screenPoint.xyz - camPos;
	dir = normalize(dir);

	r.direction = dir;
	r.power = 1.0f;
	return r;
}
#endif // PRIMARYRAYCOMPUTE