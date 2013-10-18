#ifndef STRUCTSCOMPUTE
#define STRUCTSCOMPUTE

#define noThreadsX 32
#define noThreadsY 32
#define noThreadsZ 1
#define noDGroupsX 25
#define noDGroupsY 25
#define noDGroupsZ 1
#define BOUNCES 3

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
	bool		firstPass;
};

struct Ray
{
	float3 origin;
	float3 direction;
	float power;
};

struct Sphere
{
	float3 position;
	float4 color;
	float  radius;
	int id;
	float reflection; 
};

struct HitData
{
	float4 color;
	float distance;
	float3 normal;
	int	id;
	Ray r;
	float reflection;
};

struct Vertex
{
	float3	position;
	float4	color;
	int		id;
	float	reflection;
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
	float range;
};

#endif // STRUCTSCOMPUTE