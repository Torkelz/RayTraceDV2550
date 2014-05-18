#ifndef STRUCTSCOMPUTE
#define STRUCTSCOMPUTE

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

struct HLSLNode
{
	float3 boundHigh;
	float3 boundLow;

	int parentId;
	int nodes[8];

	int startVertexLocation;
	int nrVertices;
};

#endif // STRUCTSCOMPUTE