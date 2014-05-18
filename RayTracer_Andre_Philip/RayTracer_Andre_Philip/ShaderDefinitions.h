#pragma once

#include <string>
#include "ComputeHelp.h"

struct ShaderDefinitions
{
	std::string noThreadsX;
	std::string noThreadsY;
	std::string noThreadsZ;
	std::string noDGroupsX;
	std::string noDGroupsY;
	std::string noDGroupsZ;
	std::string BOUNCES;
	std::string LIGHTS;
	bool firstPass;
	float avgCompRay;
	float avgIntersect;
	float avgColor;

	ComputeShader*	CS_ComputeRay;
	ComputeShader*	CS_IntersectionStage;
	ComputeShader*	CS_ColorStage;

	ShaderDefinitions();
	ShaderDefinitions(ShaderDefinitions &&p_Other);
	~ShaderDefinitions();
};