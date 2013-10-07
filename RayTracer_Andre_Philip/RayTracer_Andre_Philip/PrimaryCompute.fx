
//struct Ray
//{
//	float3 origin;
//	float3 direction;
//};

//Ray CreateRay(uint3 thread, int screenWidth, int screenHeight, float3 camPos, matrix projMatInv, matrix viewMatInv)
//{
	/*Ray r;
	r.origin = camPos;

	float screenSpaceX = ((((float)thread.x/screenWidth)  *2) - 1.0f);
	float screenSpaceY = (((1.0f -((float)thread.y/screenHeight)) * 2) - 1.0f);

	float4 screenPoint = float4(screenSpaceX, screenSpaceY, 1,1);
	screenPoint = mul(screenPoint, projMatInv);

	screenPoint /= screenPoint.w;
	screenPoint = mul(screenPoint, viewMatInv);

	float3 dir = screenPoint.xyz - camPos;
	dir = normalize(dir);

	r.direction = dir;

	return r;*/
//}