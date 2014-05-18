#ifndef COLORSTAGECOMPUTE
#define COLORSTAGECOMPUTE
#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

float3 LightSourceCalc(Ray r, float3 normal, float3 color, PointLight L, int materialID);

cbuffer cBufferdata : register(b0){cData cd;};

StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<HitData> InputHitdata : register(t1);
StructuredBuffer<PointLight> pl : register(t2);
StructuredBuffer<HLSLNode> OctTree : register(t3);
StructuredBuffer<OBJVertex> OctTreeVertices : register(t4);
StructuredBuffer<OBJMaterial> material : register(t5);

RWTexture2D<float4> output : register(u0);
RWStructuredBuffer<float4> accOutput : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);

	uint dimension;
	uint stride;
	OctTreeVertices.GetDimensions(dimension, stride);

	HitData h = InputHitdata[index];
	Sphere s;
	s.position = float3(-13,10,0);
	s.radius = 2.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;
	s.reflection = 1.f;

	if(h.id == -1)
	{
		output[ThreadID.xy] = float4(0,0,0,1);
		return;
	}

	volatile Ray L;// T�nka p� att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska g�ras.
	L.origin = h.r.origin + (h.r.direction *h.distance);
		
	const float deltaRange = 0.001f;
	volatile float returnT = 0.0f;

	float4x4 scale = cd.scale;
	volatile int increasingID = dimension;

	struct shadowData
	{
		float shadow;
		float3 direction;
	};

	//Set init values for all lights
	volatile shadowData shadowarray[LIGHTS];
	for(unsigned int i = 0; i < LIGHTS; i++)
	{
		shadowarray[i].shadow = -1.0f;
		shadowarray[i].direction = normalize(pl[i].position.xyz - L.origin);
	}

	increasingID = 0;
	if(h.id != increasingID)
	{
		for(unsigned int i = 0; i < LIGHTS; i++)
		{
			L.direction = shadowarray[i].direction;
			returnT = RaySphereIntersect(L, s);
			if(returnT < shadowarray[i].shadow || shadowarray[i].shadow < 0.0f && returnT > deltaRange)
			{
				shadowarray[i].shadow = returnT;
			}
		}
	}
	increasingID++;

	for(int j = 0; j < 36; j+=3)
	{
		if(h.id != increasingID)
		{
			for(unsigned int i = 0; i < LIGHTS; i++)
			{
				L.direction = shadowarray[i].direction;
				returnT = RayTriangleIntersection(L,Triangles[j].position, Triangles[j+1].position, Triangles[j+2].position).x;
				//returnT = returnT4.x;
				if(returnT < shadowarray[i].shadow && returnT > deltaRange || shadowarray[i].shadow < 0.0f && returnT > deltaRange)
				{
					shadowarray[i].shadow = returnT;
				}
			}
		}
		increasingID++;
	}

	for(i = 0; i < LIGHTS; i++)
	{
		L.direction = shadowarray[i].direction;
		if(RayAABB(L,  OctTree[0].boundLow, OctTree[0].boundHigh))
		{
			int stackIndex = 0;
			volatile HLSLNode stack[20];

			stack[++stackIndex] = OctTree[0];
			volatile HLSLNode node;
			
			//Depth first search
			[allow_uav_condition]
			while(stackIndex > 0)
			{
				node = stack[stackIndex--];

				if(node.nrVertices > 0)
				{
					int startTri = node.startVertexLocation;
					[allow_uav_condition]
					for(int tri = 0; tri < node.nrVertices; tri++)
					{
						int vertexIndex = startTri + (tri * 3);
						//Avoid selfcollision
						if(h.id == vertexIndex) continue;

						returnT = RayTriangleIntersection(L,mul(float4(OctTreeVertices[vertexIndex].position,1), scale).xyz, 
							mul(float4(OctTreeVertices[vertexIndex + 1].position,1), scale).xyz, 
							mul(float4(OctTreeVertices[vertexIndex + 2].position,1), scale).xyz).x;
					
						if(returnT < shadowarray[i].shadow && returnT > deltaRange || shadowarray[i].shadow < 0.0f && returnT > deltaRange)
						{
							shadowarray[i].shadow = returnT;
						}
					}
				}
				//[allow_uav_condition]
				for(int i = 0; i < 8; i++)
				{
					if(node.nodes[i] > 0)
					{
						if(RayAABB(L,  OctTree[node.nodes[i]].boundLow, OctTree[node.nodes[i]].boundHigh))
						{
							stack[++stackIndex] = OctTree[node.nodes[i]];
						}
					}
				}
			}
		}
	}

	volatile float4 color = float4(0,0,0,0);
	for(i = 0; i < LIGHTS; i++)
	{
		if(!(shadowarray[i].shadow > deltaRange && shadowarray[i].shadow < length(pl[i].position.xyz - L.origin)))
		{
			L.direction = shadowarray[i].direction;
			color += h.color * float4(LightSourceCalc(L, h.normal, h.color.xyz, pl[i], h.materialID),0.f);
		}
	}
	accOutput[index] += color * h.r.power;
		
	output[ThreadID.xy] = saturate(accOutput[index]);
}

float3 LightSourceCalc(Ray r, float3 normal, float3 color, PointLight L, int materialID)
{
		
        float3 litColor = 0;
        //The vector from surface to the light
        float3 lightVec = L.position.xyz - r.origin;
        float lightintensity;
        float3 lightDir;
        float3 reflection;
        float3 specular = 1;
		float3 ambient = L.ambient.xyz;
		float3 diffuse = L.diffuse.xyz;
		float shininess = 32;

		if(materialID != -1)
		{
			diffuse  *= material[materialID].Kd.xyz;
			ambient	 *= material[materialID].Ka.xyz;
			specular *= material[materialID].Ks.xyz;
			shininess = material[materialID].Ks.w;
		}
        //the distance deom surface to light
        float d = length(lightVec);
        float fade;
        if(d > L.range)
                return float3(0.0f, 0.0f, 0.0f);
        fade = 1 - (d/ L.range);
        //Normalize light vector
        lightVec /= d;
		litColor = ambient.xyz;
        //Add ambient light term
        
        lightintensity = saturate(dot(normal, lightVec));
        litColor += diffuse.xyz * lightintensity;
        lightDir = -lightVec;
        if(lightintensity > 0.0f)
        {
            float3 viewDir = normalize(r.origin - cd.camPos);
            float3 ref = reflect(-lightDir, normalize(normal));
			float scalar = max(dot(ref, viewDir), 0.0f);
			float specFac = 1.0f;
			for(int i = 0; i < shininess;i++)
				specFac *= scalar;
            litColor += specular.xyz * specFac;
        }
        litColor = litColor * color;

        return litColor*fade;
}

#endif //COLORSTAGECOMPUTE