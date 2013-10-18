#ifndef COLORSTAGECOMPUTE
#define COLORSTAGECOMPUTE
#pragma pack_matrix(row_major)
#include "structsCompute.fx"
#include "IntersectionCompute.fx"

float3 LightSourceCalc(Ray r, HitData h, PointLight l);

cbuffer cBufferdata : register(b0){cData cd;};

StructuredBuffer<Vertex> Triangles : register(t0);
StructuredBuffer<HitData> InputHitdata : register(t1);
StructuredBuffer<PointLight> pl : register(t2);


RWTexture2D<float4> output : register(u0);
RWStructuredBuffer<float4> accOutput : register(u1);

[numthreads(noThreadsX, noThreadsY, noThreadsZ)]
void main( uint3 ThreadID : SV_DispatchThreadID )
{
	int index = ThreadID.x+(ThreadID.y*cd.screenWidth);
	HitData h = InputHitdata[index];
	Sphere s;
	s.position = float3(0,0,0);
	s.radius = 5.f;
	s.color = float4(0.9,0,0,1);
	s.id = 0;

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
		//float hubba = 0;   ## THE BEST VARIABLE IN THE WORLD!!!!!!
		//[unroll] //IF FPS PROBLEM REMOVE THIS
		float angle = 0.0f;

		for(int i = 0; i < 1;i++)
		{
			//NULLIFY
			t = float4(0, 0, 0, 0);			
			shadowh= -1.f;
			//RECALCULATE
			float lightDistance = length(pl[i].position.xyz - L.origin);
			L.direction = normalize(pl[i].position.xyz - L.origin);
			if(h.id != s.id)
			{
				returnT = RaySphereIntersect(L, s);
				if(returnT < shadowh || shadowh < 0.0f && returnT > deltaRange)
				{
					shadowh = returnT;
				}
			}
			for(int j = 0; j < 36; j+=3)
			{
				if(h.id != Triangles[j].id)
				{
					returnT = RayTriangleIntersection(L,Triangles[j].position, Triangles[j+1].position, Triangles[j+2].position);
					if(returnT < shadowh && returnT > 0.f || shadowh < 0.0f && returnT > 0.f)
					{
						shadowh = returnT;
					}
				}
			}
			
			if(shadowh > deltaRange && shadowh < lightDistance)
			{
				t += 0.0f * float4(LightSourceCalc(L, h, pl[i]),0.f);
				//hubba += 1;
			}
			else
			{
				t += 1.0f * float4(LightSourceCalc(L, h, pl[i]),0.f);
				//hubba += 2.0f;
			}
			
			color += (h.color ) * t;//* float4(0.1f,0.1f,0.1f,1)
		}
		//color /= hubba;
		accOutput[index] += color * h.r.power;
		output[ThreadID.xy] = accOutput[index];

	}
}

float3 LightSourceCalc(Ray r, HitData hd, PointLight L)
{
        float3 litColor = float3(0.0f, 0.0f, 0.0f);
        //The vector from surface to the light
        float3 lightVec = L.position.xyz - r.origin;
        float lightintensity;
        float3 lightDir;
        float3 reflection;
        float4 specular;
        //the distance deom surface to light
        float d = length(lightVec);
        float fade;
        if(d > L.range)
                return float3(0.0f, 0.0f, 0.0f);
        fade = 1 - (d/ L.range);
        //Normalize light vector
        lightVec /= d;

        //Add ambient light term
        litColor = L.ambient.xyz;

        lightintensity = saturate(dot(hd.normal, lightVec));
        litColor += L.diffuse.xyz * lightintensity;
        lightDir = -lightVec;
        if(lightintensity > 0.0f)
        {
            float shininess = 32;
            float3 viewDir = normalize(r.origin - cd.camPos);
            float3 ref = reflect(-lightDir, normalize(hd.normal));
            float specFac = pow(max(dot(ref, viewDir), 0.0f), shininess);
            litColor += float3(1.0f, 1.0f, 1.0f) * specFac;
        }
        litColor = litColor * hd.color.xyz;

        return litColor*fade;

	////PHONG
	//float4 diffuse = { 1.0f, 0.0f, 0.0f, 1.0f};
	//diffuse = l.diffuse;
	//float4 ambient = { 0.1f, 0.0f, 0.0f, 1.0f};
	//ambient = l.ambient;

	//float3 Normal = normalize(h.normal);
	//float3 LightDir = normalize(l.position.xyz - r.origin);
	//float3 ViewDir = -normalize(r.origin - cd.camPos); 
	//float4 diff = saturate(dot(Normal, LightDir)); // diffuse component

	//// R = 2 * (N.L) * N - L
	//float3 Reflect = normalize(2* diff.xyz * h.normal - LightDir); 
	//float4 specular = pow(saturate(dot(Reflect, ViewDir)), 20); // R.V^n

	//// I = Acolor + Dcolor * N.L + (R.V)n
	//return ambient.xyz + diffuse.xyz * diff.xyz + specular.xyz;
}

#endif //COLORSTAGECOMPUTE