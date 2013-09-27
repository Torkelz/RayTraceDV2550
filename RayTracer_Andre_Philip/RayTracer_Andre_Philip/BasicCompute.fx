//--------------------------------------------------------------------------------------
// BasicCompute.fx
// Direct3D 11 Shader Model 5.0 Demo
// Copyright (c) Stefan Petersson, 2012
//--------------------------------------------------------------------------------------
#pragma pack_matrix(row_major)

struct Sphere
{
	float3 position;
	float3 color;
	float	radius;
};


cbuffer cBufferdata : register(b0)
{
	matrix		viewMatInv;
	matrix		projMatInv;
	float3		camPos;
	int			screenWidth;
	int			screenHeight;
	float		fovX;
	float		fovY;
};

struct Ray
{
	float3 origin;
	float3 direction;
};

RWTexture2D<float4> output : register(u0);

//[numthreads(32, 32, 1)]
//void main( uint3 threadID : SV_DispatchThreadID )
//{
//	output[threadID.xy] = float4(float3(1,0,1) * (1 - length(threadID.xy - float2(400, 400)) / 400.0f), 1);
//}

[numthreads(32, 32, 1)]
void main( uint3 threadID : SV_DispatchThreadID )
{
	Ray r;
	r.origin = camPos;

	float screenSpaceX = ((((float)threadID.x/screenWidth)  *2) - 1.0f);
	float screenSpaceY = (((1.0f -((float)threadID.y/screenHeight)) * 2) - 1.0f);

	float4 test = float4(screenSpaceX, screenSpaceY, 1,1);
	test = mul(test, projMatInv);

	test /= test.w;
	//test = mul(test, viewMatInv);

	float3 dir = test.xyz - camPos;
	dir = normalize(dir);

	dir.z = 0.0f;
	output[threadID.xy] = float4(dir,1);
}
