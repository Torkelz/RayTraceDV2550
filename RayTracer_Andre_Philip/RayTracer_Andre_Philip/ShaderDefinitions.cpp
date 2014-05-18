#include "ShaderDefinitions.h"

ShaderDefinitions::~ShaderDefinitions()
{
	SAFE_DELETE(CS_ComputeRay);
	SAFE_DELETE(CS_IntersectionStage);
	SAFE_DELETE(CS_ColorStage);
}

ShaderDefinitions::ShaderDefinitions( ShaderDefinitions &&p_Other ) : noThreadsX(std::move(p_Other.noThreadsX)),noThreadsY(std::move(p_Other.noThreadsY)),noThreadsZ(std::move(p_Other.noThreadsZ)),
	noDGroupsX(std::move(p_Other.noDGroupsX)),noDGroupsY(std::move(p_Other.noDGroupsY)),noDGroupsZ(std::move(p_Other.noDGroupsZ)),
	BOUNCES(std::move(p_Other.BOUNCES)),LIGHTS(std::move(p_Other.LIGHTS)),
	CS_ComputeRay(std::move(p_Other.CS_ComputeRay)), CS_IntersectionStage(std::move(p_Other.CS_IntersectionStage)), 
	CS_ColorStage(std::move(p_Other.CS_ColorStage)),	firstPass(std::move(p_Other.firstPass)),
	avgCompRay(std::move(p_Other.avgCompRay)),avgIntersect(std::move(p_Other.avgIntersect)),avgColor(std::move(p_Other.avgColor))
{
	p_Other.CS_ComputeRay = nullptr;
	p_Other.CS_IntersectionStage = nullptr;
	p_Other.CS_ColorStage = nullptr;
}

ShaderDefinitions::ShaderDefinitions() : noThreadsX(),noThreadsY(),noThreadsZ(),
	noDGroupsX(),noDGroupsY(),noDGroupsZ(),BOUNCES(),LIGHTS(),
	CS_ComputeRay(nullptr), CS_IntersectionStage(nullptr), CS_ColorStage(nullptr),
	firstPass(true),avgCompRay(0.f),avgIntersect(0.f),avgColor(0.f)
{

}
