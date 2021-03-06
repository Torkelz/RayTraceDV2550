#include "OBJLoader.h"

Loader::Loader(string p_workDirektory)
{
	numberOfIndices = 0;
	materialID = -1;
	workDirectory = p_workDirektory;
}
	
bool Loader::loadFile(string fileName)
{
	ifstream input((workDirectory + fileName).c_str());
	string buffer;
	
	if (!input)
	{
		return false;
	}
	while ( getline(input, buffer))
	{
		istringstream line(buffer);
		string line_t;
		string fileName_p;
		if (buffer.substr(0,6) == "mtllib")
		{
			line >> line_t >> fileName_p;
			
			mtlLoader(fileName_p);
		}
		else if (buffer.substr(0,6) == "usemtl")
		{
			string name;
			line >> line_t >> name;
			mtlName.push_back(name);
		}
		else if (buffer.substr(0,2) == "vn")
		{
			float f1, f2, f3;
			line >> line_t >> f1 >> f2 >> f3;

			Normals.push_back(D3DXVECTOR3(f1,f2,f3));
		}
		else if (buffer.substr(0,2) == "vt")
		{
			float f1, f2;
			line >> line_t >> f1 >> f2;
			TexCoords.push_back(D3DXVECTOR2(f1,1-f2));
		}
		else if (buffer.substr(0,1) == "v")
		{
			float f1, f2, f3;
			line >> line_t >> f1 >> f2 >> f3;
			Positions.push_back(D3DXVECTOR3(f1,f2,f3));
		}
		else if(buffer.substr(0,1) == "f")
		{
			UINT iPosition, iNormal, iTexCoord;
			
			for (UINT iFace = 0; iFace < 3; iFace++)
			{
				if(iFace == 0)
				{
					line.ignore();
					line >> iPosition;
				}
				else
				{
					line >> iPosition;
				}
				vertex.position = Positions[iPosition - 1];
				if('/' == line.peek())
				{
					line.ignore();

					if('/' != line.peek())
					{
						line >> iTexCoord;
						vertex.texCoord = TexCoords[iTexCoord -1];
					}
					if('/' == line.peek())
					{
						line.ignore();
						line >> iNormal;
						vertex.normal = Normals[iNormal-1];
					}
					vertex.materialID = materialID;
					Vertices.push_back(vertex);
					//DWORD index = addVertex2(&vertex);
					//indices.push_back(index);
					numberOfIndices++;
				}
			}
		}		
	}
	input.close();
	vector<OBJVertex>(Vertices).swap(Vertices);
}
void Loader::mtlLoader(string fileName)
{
	ifstream input(workDirectory + fileName.c_str());
	string buffer, mapName;
	float f1,f2,f3;
	unsigned char round = (unsigned)'1';
	if (!input)
	{
		printf("HELLO");
	}
	
	while(input >> buffer)
	{
		if (buffer == "newmtl")
		{
			if(round == (unsigned)'1')
			{
				input >> loadMtl.name;
				round = (unsigned)'0';
			}
			else
			{
				mtl.push_back(loadMtl);
			}
		}
		else if(buffer == "Ns")
		{
			input >> loadMtl.Ns;
		}
		else if(buffer == "Kd")
		{
			input >> f1 >> f2 >> f3;
			loadMtl.Kd = D3DXVECTOR3(f1,f2,f3);
		}
		else if(buffer == "Ka")
		{
			input >> f1 >> f2 >> f3;
			loadMtl.Ka = D3DXVECTOR3(f1,f2,f3);
		}
		else if (buffer == "Ks")
		{
			input >> f1 >> f2 >> f3;
			loadMtl.Ks = D3DXVECTOR3(f1,f2,f3);
		}
		else if (buffer == "map_Kd")
		{
			input >> mapName;
			strcpy_s(loadMtl.map_Kd, (workDirectory + mapName).c_str());
		}
		else if (buffer == "Ni")
		{
			input >> loadMtl.Ni;
		}
	}
	materialID++;
	input.close();
	mtl.push_back(loadMtl);
}

DWORD Loader::addVertex2(OBJVertex* vertextemp)
{
	for (int i = 0; i < (int)Vertices.size(); i++)
	{
		if(Vertices[i].position == vertextemp->position)
			return i;
		
	}
	int intt = Vertices.size();
	vertextemp->materialID = materialID;
	Vertices.push_back( *vertextemp );
	return intt;
}

D3DXVECTOR3 Loader::GetVertexPos(int i)
{
	return Vertices.at(i).position;
}
D3DXVECTOR3 Loader::GetVertexNorm(int i)
{
	return Vertices.at(i).normal; 
}
D3DXVECTOR2 Loader::GetVertexTexCoord(int i)
{
	return Vertices.at(i).texCoord;
}
int Loader::GetVertBuffLength()
{
	return Vertices.size();
}
vector<DWORD> Loader::getIndices()
{
	return indices;
}
vector<OBJVertex> Loader::getVertices()
{
	return Vertices;
}
Material Loader::GetMaterialAt(int i)
{
	return mtl.at(i);
}
int Loader::getMaterialId()
{
	return materialID;
}