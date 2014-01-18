#ifndef OCTTREE_H
#define OCTTREE_H
#include "stdafx.h"
typedef D3DXVECTOR4 float4;
typedef D3DXVECTOR3 float3;
typedef D3DXVECTOR2 float2;
typedef D3DXMATRIX float4x4;

#include "structsCompute.fx"

struct OctNode
{
	D3DXVECTOR3 boundHigh;
	D3DXVECTOR3 boundLow;
	
	std::vector<OctNode*> nodes;
	std::vector<D3DXVECTOR3> vertices;
};
struct Bounds
{
	D3DXVECTOR3 boundHigh;
	D3DXVECTOR3 boundLow;
};

class OctTree
{
public:
	OctTree(void);
	~OctTree(void);

	void CreateTree(OBJVertex* pdata, int numElements);
	void TreeCleanup(OctNode* node);

private:
	void findBounds(OBJVertex* pdata, int numElements, D3DXVECTOR3 &boundHigh,D3DXVECTOR3 &boundLow);
	void subdivideTree(OctNode* node, int depth, OBJVertex* pdata);
	void cleanEmptyNodes(OctNode* node);
	int getDXVecElement(int p, D3DXVECTOR3* d);
	int getNrNodes(OctNode* node);
	int getNrLeafNodes(OctNode* node);
	std::vector<Bounds> calcSubBounds(D3DXVECTOR3 boundHigh, D3DXVECTOR3 boundLow);

	OctNode* root;
	int maxDepth;

};

#endif