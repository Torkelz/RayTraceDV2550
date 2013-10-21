#include "stdafx.h"
#include <fstream>
#include <sstream>
typedef D3DXVECTOR4 float4;
typedef D3DXVECTOR3 float3;
typedef D3DXVECTOR2 float2;
typedef D3DXMATRIX float4x4;

#include "structsCompute.fx"



using namespace std;

struct Material
{
	string name;
	float3 Kd;
	float3 Ka;
	float3 Ks;
	char map_Kd[MAX_PATH];
	float Ni;
	float Ns;
};

class Loader
{
public:
	Loader(string p_workDirectory);
	bool loadFile(string fileName);
	D3DXVECTOR3 GetVertexPos(int i);
	D3DXVECTOR3 GetVertexNorm(int i);
	D3DXVECTOR2 GetVertexTexCoord(int i);
	int GetVertBuffLength();
	int getMaterialId();
	void mtlLoader(string fileName);
	Material GetMaterialAt(int i);
	DWORD addVertex2(OBJVertex* vertextemp);
	vector<DWORD> getIndices();
	vector<OBJVertex> getVertices();
private:
	vector<string> mtlName;
	string fileNameTex;
	string workDirectory;
	Material loadMtl;
	int numberOfIndices;
	int materialID;
	vector<Material> mtl;
	OBJVertex vertex;
	vector<D3DXVECTOR3> Positions;
	vector<D3DXVECTOR2> TexCoords;
	vector<D3DXVECTOR3> Normals; 
	vector<OBJVertex> Vertices;
	vector<DWORD> indices;
};