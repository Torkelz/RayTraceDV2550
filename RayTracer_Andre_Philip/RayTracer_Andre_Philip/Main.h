
struct PointLight
{
	D3DXVECTOR4 position;
	D3DXVECTOR4 color;
	D3DXVECTOR4 diffuse;
	D3DXVECTOR4 ambient;
	D3DXVECTOR4 specular;
	D3DXVECTOR4 att;
	PointLight(){}

	PointLight(D3DXVECTOR4 _position,	D3DXVECTOR4 _color, D3DXVECTOR4 _diffuse, D3DXVECTOR4 _ambient, D3DXVECTOR4 _specular, D3DXVECTOR4 _att)
	{
		position = _position;
		color = _color;
		diffuse = _diffuse;
		ambient = _ambient;
		specular = _specular;
		att = _att;
	}
};

struct cBufferdata
{
	D3DXMATRIX	viewMat;
	D3DXMATRIX	projMatInv;
	D3DXMATRIX  WVP;
	D3DXVECTOR3	camPos;
	int			screenWidth;
	int			screenHeight;
	float		fovX;
	float		fovY;
};

struct Vertex
{
	D3DXVECTOR3 position;
	D3DXVECTOR4 color;
	int id;
	Vertex(){};

	Vertex(D3DXVECTOR3 _position, D3DXVECTOR4 _color, int _id)
	{
		position = _position;
		color = _color;
		id = _id;
	}
};



PointLight g_lights[] = 
{
	PointLight(D3DXVECTOR4(-10,0,-10,1), D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(0,0,-10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(10,0,-10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(10,0,0,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(10,0,10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(0,0,10,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(-10,0,10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(-10,0,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(0, 20, 0,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	PointLight(D3DXVECTOR4(0,-20,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1))
};