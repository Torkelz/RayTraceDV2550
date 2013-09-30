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
	float  radius;
};

struct PointLight
{
	float3 position;
	float3 color;
};

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

struct Ray
{
	float3 origin;
	float3 direction;
};
RWTexture2D<float4> output : register(u0);
//Methods
float3 LightSourceCalc(float3 pStart, float3 pLight);
float3 RaySphereIntersect(Ray r, Sphere s);

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
	Sphere s;
	s.position = float3(0,0,0);
	s.radius = 5.f;
	s.color = float3(1,0,0);

	float screenSpaceX = ((((float)threadID.x/screenWidth)  *2) - 1.0f);
	float screenSpaceY = (((1.0f -((float)threadID.y/screenHeight)) * 2) - 1.0f);

	float4 screenPoint = float4(screenSpaceX, screenSpaceY, 1,1);
	screenPoint = mul(screenPoint, projMatInv);

	screenPoint /= screenPoint.w;
	screenPoint = mul(screenPoint, viewMatInv);

	float3 dir = screenPoint.xyz - camPos;
	dir = normalize(dir);

	r.direction = dir;
	dir.z = 0.0f;

	//output[threadID.xy] = float4(dir,1);
	output[threadID.xy] = float4(RaySphereIntersect(r, s),1);
}

float3 RaySphereIntersect(Ray r, Sphere sp)
{
	float3 l = sp.position - r.origin;
	float s = dot(l, r.direction);
	float lsq = length(l)*length(l);
	float rsq = sp.radius * sp.radius;

	if( s < 0 && lsq > rsq )
		return float3(0,0,0);
	
	float msq = lsq - (s*s);

	if(msq > rsq)
		return float3(0,0,0);

	float q = sqrt(rsq - msq);
	float t = 0.f;

	if(lsq > rsq)
		t = s - q;
	else
		t = s + q;
	
	return sp.color;
}

float3 LightSourceCalc(Ray r, PointLight l);
{

}