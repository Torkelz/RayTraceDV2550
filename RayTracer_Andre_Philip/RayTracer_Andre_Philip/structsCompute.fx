#ifndef STRUCTSCOMPUTE
#define STRUCTSCOMPUTE

#define noThreadsX 32
#define noThreadsY 32
#define noThreadsZ 1
#define noDGroupsX 25
#define noDGroupsY 25
#define noDGroupsZ 1

struct cData
{
	float4x4	viewMatInv;
	float4x4	projMatInv;
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

struct Sphere
{
	float3 position;
	float4 color;
	float  radius;
	int id;
};

struct HitData
{
	float4 color;
	float distance;
	float3 normal;
	int	id;
	Ray r;
};

struct Vertex
{
	float3 position;
	float4 color;
	int id;
	//More to come!!
};

struct PointLight
{
	float4 position;
	float4 color;
	float4 diffuse;
	float4 ambient;
	float4 specular;
	float4 att;
};

#endif // STRUCTSCOMPUTE