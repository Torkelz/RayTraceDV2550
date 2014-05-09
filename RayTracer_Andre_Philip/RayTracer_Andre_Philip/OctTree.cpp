#include "OctTree.h"


OctTree::OctTree(void)
{
	root = NULL;
	maxDepth = 1;
}


OctTree::~OctTree(void)
{
}

void OctTree::CreateTree(OBJVertex* pdata, int numelements)
{
	root = new OctNode();
	D3DXVECTOR3 boundHigh, boundLow;
	findBounds(pdata,numelements, boundHigh, boundLow);
	std::vector<OBJVertex*> data;
	for(int i = 0; i < numelements; i++)
		data.push_back(&pdata[i]);
	root->boundHigh = boundHigh;
	root->boundLow = boundLow;
	for(int i = 0; i < numelements; i+=3)
	{
		root->vertices.push_back(D3DXVECTOR3(i,i+1,i+2));
	}
	int d = 0;
	subdivideTree(root, d, pdata);
	//int j = getNrNodes(root);
	

	cleanEmptyNodes(root);
	//j = getNrNodes(root);
	OctNode* node = root;
	for(int i = 0; i < maxDepth; i++)
		TreeCleanup(node);

	//j = getNrNodes(root);
	//int ll = getNrLeafNodes(root);
	//int u = 0;

	OctNode *currNode = root;
	int ids = 0;
	currNode->id = ids;
	assignIDs(currNode, ids);
}

void OctTree::TreeCleanup(OctNode* node)
{
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		if ( node->nodes.at(i)->nodes.size() == 1)
		{
			node->nodes.at(i) = node->nodes.at(i)->nodes.at(0);
		}

		TreeCleanup(node->nodes.at(i));
	}
}

void OctTree::OrganizeData(std::vector<OBJVertex> &pVertices, std::vector<HLSLNode> &pNodes, const OBJVertex* pdata)
{
	OctNode *currNode = root;
	HLSLNode hl;
	hl.parentId = -1;
	hl.boundHigh = currNode->boundHigh;
	hl.boundLow = currNode->boundLow;
	hl.nrVertices = currNode->vertices.size();
	hl.startVertexLocation = 0;
	if(hl.nrVertices > 0)
	{
		hl.startVertexLocation = pVertices.size();
		for (int j = 0; j < hl.nrVertices; j++)
		{
			pVertices.push_back(pdata[(int)currNode->vertices.at(j).x]);
			pVertices.push_back(pdata[(int)currNode->vertices.at(j).y]);
			pVertices.push_back(pdata[(int)currNode->vertices.at(j).z]);
		}
	}
	for(unsigned int h = 0; h < 8; h++)
		hl.nodes[h] = -1;
	for(unsigned int i = 0; i < currNode->nodes.size(); i++)
		hl.nodes[i] = currNode->nodes.at(i)->id;
	pNodes.push_back(hl);

	OrganizeDataTraverse(pVertices,pNodes, currNode, pdata);
}

void OctTree::OrganizeDataTraverse(std::vector<OBJVertex> &pVertices, std::vector<HLSLNode> &pNodes, OctNode* node,  const OBJVertex* pdata)
{
	HLSLNode hlnode;
	hlnode.parentId = node->id;
	hlnode.nrVertices = 0;
	hlnode.startVertexLocation = 0;

	for(unsigned int h = 0; h < 8; h++)
		hlnode.nodes[h] = -1;

	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		hlnode.boundHigh = node->nodes.at(i)->boundHigh;
		hlnode.boundLow = node->nodes.at(i)->boundLow;

		hlnode.nrVertices = node->nodes.at(i)->vertices.size();
		hlnode.startVertexLocation = 0;
		if(hlnode.nrVertices > 0)
		{
			hlnode.startVertexLocation = pVertices.size();
			for (int j = 0; j < hlnode.nrVertices; j++)
			{
				pVertices.push_back(pdata[(int)node->nodes.at(i)->vertices.at(j).x]);
				pVertices.push_back(pdata[(int)node->nodes.at(i)->vertices.at(j).y]);
				pVertices.push_back(pdata[(int)node->nodes.at(i)->vertices.at(j).z]);
			}
		}

		
		for (unsigned int j = 0; j < node->nodes.at(i)->nodes.size(); j++)
		{
			hlnode.nodes[j] = node->nodes.at(i)->nodes.at(j)->id;
		}
		

		pNodes.push_back(hlnode);
	}
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		OrganizeDataTraverse(pVertices,pNodes, node->nodes.at(i), pdata);
	}
}

void OctTree::assignIDs(OctNode* node, int &id)
{
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		node->nodes.at(i)->id = ++id;
	}
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		assignIDs(node->nodes.at(i), id);
	}
}

int OctTree::getNrNodes(OctNode* node)
{
	int k = 0;
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		k++;
		k += getNrNodes(node->nodes.at(i));
	}
	return k;
}
int OctTree::getNrLeafNodes(OctNode* node)
{
	int k = 0;
	for(unsigned int i = 0; i < node->nodes.size(); i++)
	{
		
		if(node->nodes.at(i)->nodes.size() == 0)
			k++;
		k += getNrLeafNodes(node->nodes.at(i));
	}
	return k;
}
void OctTree::cleanEmptyNodes(OctNode* node)
{
	for(int i = node->nodes.size()-1; i >= 0;i--)
	{
		if(node->nodes.at(i)->nodes.size() == 0 && node->nodes.at(i)->vertices.size() == 0)
			node->nodes.erase(node->nodes.begin()+i);
		
	}
	for(unsigned int i = 0; i < node->nodes.size(); i++)
		cleanEmptyNodes(node->nodes.at(i));
}
void OctTree::subdivideTree(OctNode* node, int depth, OBJVertex* pdata)
{
	if(node->vertices.size() > 12 && depth < maxDepth)//depth is a failsafe
	{
		node->nodes.resize(8);
		std::vector<Bounds> b = calcSubBounds(node->boundHigh, node->boundLow);
		for(int i = 0; i < 8;i++)
		{
			node->nodes.at(i) = new OctNode();
			node->nodes.at(i)->boundHigh = b.at(i).boundHigh;
			node->nodes.at(i)->boundLow = b.at(i).boundLow;
		}
		D3DXVECTOR3 pos;
		bool intersect = false;
		for(unsigned int i = 0; i < node->vertices.size();i++)
		{			
			for(int j = 0; j < 8; j++)
			{
				for(int k = 0; k < 3; k++)
				{
					if(pointAABB(pdata[getDXVecElement(k,&node->vertices.at(i))].position,
						b.at(j).boundLow, b.at(j).boundHigh ))
					{
						node->nodes.at(j)->vertices.push_back(node->vertices.at(i));
						break;
					}


					////pos = node->vertices.at(i);
					//pos = pdata[getDXVecElement(k,&node->vertices.at(i))].position;
					//if((pos.x >= b.at(j).boundLow.x &&
					//	pos.y >= b.at(j).boundLow.y &&
					//	pos.z >= b.at(j).boundLow.z) &&
					//	(pos.x <= b.at(j).boundHigh.x &&
					//	pos.y <= b.at(j).boundHigh.y &&
					//	pos.z <= b.at(j).boundHigh.z))
					//{
					//	/*int temp = i-(i%3);
					//	for(int k = 0; k < 3;k++)*/
					//		//node->nodes.at(j)->vertices.push_back(node->vertices.at(temp+k));
					//	node->nodes.at(j)->vertices.push_back(node->vertices.at(i));
					//	break;
					//}
				}
			}
		}
		for(int i = 7; i >= 0;i--)
		{
			if(node->nodes.at(i)->vertices.size() == 0)
				node->nodes.erase(node->nodes.begin()+i);
		}
		node->vertices.clear();
		depth += 1;
		for(unsigned int i = 0; i < node->nodes.size();i++)
		{
			subdivideTree(node->nodes.at(i), depth, pdata);
		}
	}
}

std::vector<Bounds> OctTree::calcSubBounds(D3DXVECTOR3 boundHigh, D3DXVECTOR3 boundLow)
{
	std::vector<Bounds> b;
	D3DXVECTOR3 center = (boundHigh-boundLow)/2 + boundLow;
	Bounds bound;
	//             boundHigh - largest values
	// |----||----|		+Y
	// | 0	|| 1  |		^
 	// |----||----|		+Z ->+X	
	// |----||----| seen from above
	// | 3	|| 2  |
 	// |----||----|
	//boundLow - lower values
	//LowerPart
	float dx = boundHigh.x-center.x;
	float dz = boundHigh.z-center.z;
	D3DXVECTOR3 lowToCenter = center - boundLow;

	bound.boundLow = boundLow;
	bound.boundHigh = center;
	b.push_back(bound);


	bound.boundLow = D3DXVECTOR3(boundLow.x + lowToCenter.x,boundLow.y,boundLow.z);
	bound.boundHigh = bound.boundLow + lowToCenter;
	b.push_back(bound);

	bound.boundLow = D3DXVECTOR3(boundLow.x,boundLow.y,boundLow.z  + lowToCenter.z);
	bound.boundHigh = bound.boundLow + lowToCenter;
	b.push_back(bound);

	bound.boundLow = D3DXVECTOR3(boundLow.x  + lowToCenter.x,boundLow.y,boundLow.z  + lowToCenter.z);
	bound.boundHigh = bound.boundLow + lowToCenter;
	b.push_back(bound);

	//bound.boundHigh = D3DXVECTOR3(center.x,center.y,boundHigh.z);
	//bound.boundLow = D3DXVECTOR3(boundLow.x,boundLow.y,center.z);
	//b.push_back(bound);
	//float dx = boundHigh.x-center.x;
	//bound.boundHigh.x	+= dx;
	//bound.boundLow.x	+= dx;
	//b.push_back(bound);
	//float dz = boundHigh.z-center.z;
	//bound.boundHigh.z	-= dz;
	//bound.boundLow.z	-= dz;
	//b.push_back(bound);
	//float x = boundHigh.x-boundLow.x;
	//bound.boundHigh.x	-= x;
	//bound.boundLow.x	-= x;
	//b.push_back(bound);


	//Upper
	//float changeY = boundHigh.y-center.y;
	for(int i = 0; i < 4;i++)
	{
		Bounds bs = b.at(i);
		bs.boundHigh.y += lowToCenter.y;
		bs.boundLow.y  += lowToCenter.y;
		b.push_back(bs);
	}

	return b;
}

void OctTree::findBounds(OBJVertex* pdata, int numElements, D3DXVECTOR3 &boundHigh,D3DXVECTOR3 &boundLow)
{
	boundHigh = D3DXVECTOR3(0,0,0);
	boundLow = D3DXVECTOR3(0,0,0);

	for(int i = 0; i < numElements;i++)
	{
		D3DXVec3Maximize(&boundHigh,&boundHigh,&pdata[i].position);
		D3DXVec3Minimize(&boundLow,&boundLow,&pdata[i].position);			
	}
}

int OctTree::getDXVecElement( int p, D3DXVECTOR3* d )
{
	switch (p)
	{
	case 0:
		return (int)d->x;
	case 1:
		return (int)d->y;
	case 2:
		return (int)d->z;
	}
}

bool OctTree::pointAABB( D3DXVECTOR3 p, D3DXVECTOR3 low, D3DXVECTOR3 high )
{
	if (p.x>high.x) return false;
	if (p.x<low.x) return false;
	if (p.y>high.y) return false;
	if (p.y<low.y) return false;
	if (p.z>high.z) return false;
	if (p.z<low.z) return false;
	return true;
}
