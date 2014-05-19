#ifndef MAIN_H
#define MAIN_H

typedef D3DXVECTOR4 float4;
typedef D3DXVECTOR3 float3;
typedef D3DXVECTOR2 float2;
typedef D3DXMATRIX float4x4;

#include "structsCompute.fx"



inline Light CreatePointLight(D3DXVECTOR4 _position,	D3DXVECTOR4 _color, D3DXVECTOR4 _diffuse, D3DXVECTOR4 _ambient, D3DXVECTOR4 _specular, D3DXVECTOR4 _att, float _range)
{
	Light pl;

	pl.position = _position;
	pl.color = _color;
	pl.diffuse = _diffuse;
	pl.ambient = _ambient;
	pl.specular = _specular;
	pl.att = _att;
	pl.range = _range;
	pl.type = 0;
	return pl;
}

inline Light CreateDirectionalLight(D3DXVECTOR4 _position, D3DXVECTOR3 _direction, D3DXVECTOR4 _color)
{
	Light pl;
	pl.position = _position;
	pl.direction = _direction;
	pl.color = _color;
	pl.type = 1;
	return pl;
}

inline Vertex CreateVertex(D3DXVECTOR3 _position, D3DXVECTOR4 _color, int _id, float _reflection )
{
	Vertex v;

	v.position = _position;
	v.color = _color;
	v.id = _id;
	v.reflection = _reflection;
	return v;
}

Light g_lights[] = 
{
	CreateDirectionalLight(D3DXVECTOR4(0,0,-90,1), D3DXVECTOR3(0,0,1), D3DXVECTOR4(1,1,1,1)),
	CreatePointLight(D3DXVECTOR4(-10,0,-10,1), D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(0,0,-10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(10,0,-10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(10,0,0,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(10,0,10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(0,0,10,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(-10,0,10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(-10,0,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(0, 20, 0,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f),
	CreatePointLight(D3DXVECTOR4(0,-20,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1),75.0f)
};

#endif