#ifndef COLORSTAGECOMPUTE
#define COLORSTAGECOMPUTE
#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

float3 LightSourceCalc(Ray r, HitData h, PointLight l, int materialID);

cbuffer cBufferdata : register(b0){cData cd;};

StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<HitData> InputHitdata : register(t1);
StructuredBuffer<PointLight> pl : register(t2);

StructuredBuffer<OBJVertex> OBJ : register(t3);
StructuredBuffer<DWORD> Indices : register(t4);
StructuredBuffer<OBJMaterial> material : register(t5);


RWTexture2D<float4> output : register(u0);
RWStructuredBuffer<float4> accOutput : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);
	int increasingID = 0;

	HitData h = InputHitdata[index];
	Sphere s;
	s.position = float3(-13,10,0);
	s.radius = 2.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;
	s.reflection = 1.f;


	if(cd.firstPass)
		accOutput[index] = float4(0,0,0,0);

	if(h.id == -1)
	{
		output[ThreadID.xy] = float4(0,0,0,1);
	}
	else
	{
		float4 t = float4(0, 0, 0, 0);
		float4 color = float4(0,0,0,0);
		Ray L;// Tänka på att inte skriva till texturen sen!!!! utan att eventuellt kolla om de ska göras.
		L.origin = h.r.origin + (h.r.direction *h.distance);
		float shadowh;
		
		float deltaRange = 0.001f;
		float returnT = 0.0f;
		float4 returnT4 = float4(0,0,0,0);
		//float hubba = 0;   ## THE BEST VARIABLE IN THE WORLD!!!!!!
		//[unroll] //IF FPS PROBLEM REMOVE THIS
		//float angle = 0.0f;
		int numV = cd.nrVertices;
		float4x4 scale = cd.scale;
		float lightDistance;
		for(int i = 0; i < 1;i++)
		{
			increasingID = 0;
			//NULLIFY
			t = float4(0, 0, 0, 0);			
			shadowh= -1.f;
			//RECALCULATE
			lightDistance = length(pl[i].position.xyz - L.origin);
			L.direction = normalize(pl[i].position.xyz - L.origin);
			//if(h.id != s.id)
			if(h.id != increasingID)
			{
				returnT = RaySphereIntersect(L, s);
				if(returnT < shadowh || shadowh < 0.0f && returnT > deltaRange)
				{
					shadowh = returnT;
				}
				increasingID++;
			}
			for(int j = 0; j < 36; j+=3)
			{
				//if(h.id != Triangles[j].id)
				if(h.id != increasingID)
				{
					returnT4 = RayTriangleIntersection(L,Triangles[j].position, Triangles[j+1].position, Triangles[j+2].position);
					returnT = returnT4.x;
					if(returnT < shadowh && returnT > deltaRange || shadowh < 0.0f && returnT > deltaRange)
					{
						shadowh = returnT;
					}
				}
				increasingID++;
			}
			for(int j = 0; j < numV; j+=3)
			{
				//if(h.id != Triangles[i].id)
				if( h.id != increasingID)
				{
					returnT4 = RayTriangleIntersection(L,mul(float4(OBJ[j].position,1), scale).xyz, mul(float4(OBJ[j+1].position,1), scale).xyz, mul(float4(OBJ[j+2].position,1), scale).xyz);
					returnT = returnT4.x;

					if(returnT < shadowh && returnT > deltaRange || shadowh < 0.0f && returnT > deltaRange)
					{
						shadowh = returnT;
						j = numV;
					}
				}
				increasingID++;
			}
			
			if(shadowh > deltaRange && shadowh < lightDistance)
			{
				t += 0.0f * float4(LightSourceCalc(L, h, pl[i], h.materialID),0.f);
				//hubba += 1;
			}
			else
			{
				t += 1.0f * float4(LightSourceCalc(L, h, pl[i], h.materialID),0.f);
				//hubba += 2.0f;
			}
			
			color += (h.color ) * t;//* float4(0.1f,0.1f,0.1f,1)
		}
		//color /= hubba;
		accOutput[index] += color * h.r.power;
		output[ThreadID.xy] = accOutput[index];
	}
}

float3 LightSourceCalc(Ray r, HitData hd, PointLight L, int materialID)
{
		
        float3 litColor = float3(0.0f, 0.0f, 0.0f);
        //The vector from surface to the light
        float3 lightVec = L.position.xyz - r.origin;
        float lightintensity;
        float3 lightDir;
        float3 reflection;
        float3 specular;
		float3 ambient;
		float3 diffuse;
		float shininess;
		diffuse = L.diffuse.xyz;
		ambient = L.ambient.xyz;
		specular = float3(1.0f, 1.0f, 1.0f);
		shininess = 32;

		if(materialID != -1)
		{
			diffuse  *= material[materialID].Kd.xyz;
			ambient	 *= material[materialID].Ka.xyz;
			specular *= material[materialID].Ks.xyz;
			shininess = material[materialID].Ns.x;
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
        

        lightintensity = saturate(dot(hd.normal, lightVec));
        litColor += diffuse.xyz * lightintensity;
        lightDir = -lightVec;
        if(lightintensity > 0.0f)
        {
            
            float3 viewDir = normalize(r.origin - cd.camPos);
            float3 ref = reflect(-lightDir, normalize(hd.normal));
            //float specFac = pow(max(dot(ref, viewDir), 0.0f), shininess);
			float scalar = max(dot(ref, viewDir), 0.0f);
			float specFac = 1.0f;
			for(int i = 0; i < shininess;i++)
				specFac *= scalar;
            litColor += specular.xyz * specFac;
        }
        litColor = litColor * hd.color.xyz;

        return litColor*fade;
}

#endif //COLORSTAGECOMPUTE