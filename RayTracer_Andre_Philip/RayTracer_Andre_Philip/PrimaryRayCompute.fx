#ifndef PRIMARYRAYCOMPUTE
#define PRIMARYRAYCOMPUTE

#pragma pack_matrix(row_major)
#include "structsCompute.fx"

cbuffer cBufferdata : register(b0)
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

Ray CreateRay(uint3 thread, int screenWidth, int screenHeight, float3 camPos, matrix projMatInv, matrix viewMatInv);

RWStructuredBuffer<Ray> outputRay : register(u0);

[numthreads(32, 32, 1)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	outputRay[ThreadID.x + (ThreadID.y*screenWidth)] = CreateRay(ThreadID, screenWidth, screenHeight, camPos, projMatInv, viewMatInv);
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

	return r;
}
#endif // PRIMARYRAYCOMPUTE