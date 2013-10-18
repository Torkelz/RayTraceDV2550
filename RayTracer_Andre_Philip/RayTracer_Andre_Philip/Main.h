#ifndef MAIN_H
#define MAIN_H

typedef D3DXVECTOR4 float4;
typedef D3DXVECTOR3 float3;
typedef D3DXMATRIX float4x4;

#include "structsCompute.fx"



inline PointLight CreatePointLight(D3DXVECTOR4 _position,	D3DXVECTOR4 _color, D3DXVECTOR4 _diffuse, D3DXVECTOR4 _ambient, D3DXVECTOR4 _specular, D3DXVECTOR4 _att)
{
	PointLight pl;

	pl.position = _position;
	pl.color = _color;
	pl.diffuse = _diffuse;
	pl.ambient = _ambient;
	pl.specular = _specular;
	pl.att = _att;

	return pl;
}

inline Vertex CreateVertex(D3DXVECTOR3 _position, D3DXVECTOR4 _color, int _id, float _reflection)
{
	Vertex v;

	v.position = _position;
	v.color = _color;
	v.id = _id;
	v.reflection = _reflection;
	return v;
}

PointLight g_lights[] = 
{
	CreatePointLight(D3DXVECTOR4(-10,0,-10,1), D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(0,0,-10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(10,0,-10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(10,0,0,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(10,0,10,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(0,0,10,1),    D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(-10,0,10,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(-10,0,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(0, 20, 0,1),  D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1)),
	CreatePointLight(D3DXVECTOR4(0,-20,0,1),   D3DXVECTOR4(1,1,1,1), D3DXVECTOR4(0.5f,0.5f,0.5f,1), D3DXVECTOR4(0.4f,0.4f,0.4f,1), D3DXVECTOR4(0.05f,0.05f,0.05f,1), D3DXVECTOR4(0,0.25f,0, 1))
};

#endif