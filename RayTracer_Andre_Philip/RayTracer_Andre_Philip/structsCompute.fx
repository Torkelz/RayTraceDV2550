#ifndef STRUCTSCOMPUTE
#define STRUCTSCOMPUTE

//#define noThreadsX 1
//#define noThreadsY 4
//#define noThreadsZ 1
//#define noDGroupsX 100
//#define noDGroupsY 100
//#define noDGroupsZ 1
#define	TEST		0

#if  TEST == 0
#define BOUNCES 0
#define LIGHTS  1
#elif	TEST == 1
#define BOUNCES 10
#define LIGHTS  10
#elif	TEST == 2
#define BOUNCES 10
#define LIGHTS  1
#elif	TEST == 3
#define BOUNCES 0
#define LIGHTS  10
#elif	TEST == 4
#define BOUNCES 5
#define LIGHTS  5
#endif


struct cData
{
	float4x4	viewMatInv;
	float4x4	projMatInv;
	float4x4	WVP;
	float4x4	scale;
	float3		camPos;
	int			screenWidth;
	int			screenHeight;
	float		fovX;
	float		fovY;
	bool		firstPass;
	int			nrVertices;
	int			nrLights;
	float3		boundingVMin;
	float3		boundingVMax;
	int			groups;
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
	int materialID;
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

struct OBJVertex
{
	float3 position;
	float2 texCoord;
	float3 normal;
	int materialID;
};

struct OBJMaterial
{
	float4 Kd;
	float4 Ka;
	float4 Ks; //Shininess is the fourth value a.k.a w
	float Ni;
};

struct MortonCode
{
	unsigned int primitiveID;
	unsigned int code;
};

#endif // STRUCTSCOMPUTE