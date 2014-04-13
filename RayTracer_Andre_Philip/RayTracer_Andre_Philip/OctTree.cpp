#include "OctTree.h"


OctTree::OctTree(void)
{
	root = NULL;
	maxDepth = 3;
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
	int j = getNrNodes(root);
	

	cleanEmptyNodes(root);
	j = getNrNodes(root);
	OctNode* node = root;
	for(int i = 0; i < maxDepth; i++)
		TreeCleanup(node);

	j = getNrNodes(root);
	int ll = getNrLeafNodes(root);
	int u = 0;
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
			for(int k = 0; k < 3; k++)
			{
				//pos = node->vertices.at(i);
				pos = pdata[getDXVecElement(k,&node->vertices.at(i))].position;
				for(int j = 0; j < 8; j++)
				{
					if((pos.x >= b.at(j).boundLow.x &&
						pos.y >= b.at(j).boundLow.y &&
						pos.z >= b.at(j).boundLow.z) &&
						(pos.x <= b.at(j).boundHigh.x &&
						pos.y <= b.at(j).boundHigh.y &&
						pos.z <= b.at(j).boundHigh.z))
					{
						/*int temp = i-(i%3);
						for(int k = 0; k < 3;k++)*/
							//node->nodes.at(j)->vertices.push_back(node->vertices.at(temp+k));
						node->nodes.at(j)->vertices.push_back(node->vertices.at(i));
					}
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
	bound.boundHigh = D3DXVECTOR3(center.x,center.y,boundHigh.z);
	bound.boundLow = D3DXVECTOR3(boundLow.x,boundLow.y,center.z);
	b.push_back(bound);
	float dx = boundHigh.x-center.x;
	bound.boundHigh.x	+= dx;
	bound.boundLow.x	+= dx;
	b.push_back(bound);
	float dz = boundHigh.z-center.z;
	bound.boundHigh.z	-= dz;
	bound.boundLow.z	-= dz;
	b.push_back(bound);
	float x = boundHigh.x-boundLow.x;
	bound.boundHigh.x	-= x;
	bound.boundLow.x	-= x;
	b.push_back(bound);


	//Upper
	float changeY = boundHigh.y-center.y;
	for(int i = 0; i < 4;i++)
	{
		Bounds bs = b.at(i);
		bs.boundHigh.y += changeY;
		bs.boundLow.y  += changeY;
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
