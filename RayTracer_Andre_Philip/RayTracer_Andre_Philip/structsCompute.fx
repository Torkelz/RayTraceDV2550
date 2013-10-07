#ifndef STRUCTSCOMPUTE
#define STRUCTSCOMPUTE

struct Ray
{
	float3 origin;
	float3 direction;
};

struct Sphere
{
	float3 position;
	float3 color;
	float  radius;
	int id;
};

struct HitData
{
	float3 color;
	float distance;
	float3 normal;
	int	id;
};

struct Vertex
{
	float3 position;
	float3 color;
	int id;
	//More to come!!
};

struct PointLight
{
	float3 position;
	float4 color;
	float4 diffuse;
	float4 ambient;
	float4 specular;
};

#endif // STRUCTSCOMPUTE