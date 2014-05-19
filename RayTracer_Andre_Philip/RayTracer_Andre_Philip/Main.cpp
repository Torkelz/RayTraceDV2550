//--------------------------------------------------------------------------------------
// File: TemplateMain.cpp
//
// BTH-D3D-Template
//
// Copyright (c) Stefan Petersson 2012. All rights reserved.
//--------------------------------------------------------------------------------------
#include "stdafx.h"
#include "Camera.h"
#include "MouseInput.h"
#include "Buffer.h"

#include "ComputeHelp.h"
#include "D3D11Timer.h"
#include "Main.h"
#include "OBJLoader.h"
#include "OctTree.h"
#include "ShaderDefinitions.h"

//#define TEST
#define RESOLUTION 400

//--------------------------------------------------------------------------------------
// Global Variables
//--------------------------------------------------------------------------------------
HINSTANCE					g_hInst					= NULL;  
HWND						g_hWnd					= NULL;

IDXGISwapChain*				g_SwapChain				= NULL;
ID3D11Device*				g_Device				= NULL;
ID3D11DeviceContext*		g_DeviceContext			= NULL;

ID3D11UnorderedAccessView*  g_BackBufferUAV			= NULL;  // compute output

ComputeWrap*				g_ComputeSys			= NULL;
ComputeShader*				g_CS_ComputeRay			= NULL;
ComputeShader*				g_CS_IntersectionStage	= NULL;
ComputeShader*				g_CS_ColorStage			= NULL;

ComputeBuffer*				g_ObjectBuffer			= NULL;
ComputeBuffer*				g_lightBuffer			= NULL;
ComputeBuffer*				g_rayBuffer				= NULL;
ComputeBuffer*				g_hitDataBuffer			= NULL;
ComputeBuffer*				g_accColorBuffer		= NULL;
ComputeBuffer*				g_materialBuffer		= NULL;
ComputeBuffer*				g_OctTreeBuffer			= NULL;
ComputeBuffer*				g_OctTriangleBuffer		= NULL;

D3D11Timer*					g_Timer					= NULL;

Camera*						g_camera				= NULL;
MouseInput*					g_mouseInput			= NULL;
Buffer*						g_cBuffer				= NULL;
Loader*						g_loader				= NULL;

ID3D11ShaderResourceView*	g_objTexture			= NULL;

cData						g_cData;
float						g_cameraSpeed			= 50.f;
int							g_lightSpeed			= 10;
int							g_nrLights				= 10;

int g_Width, g_Height;
vector<ShaderDefinitions> g_Shaders;

//--------------------------------------------------------------------------------------
// Forward declarations
//--------------------------------------------------------------------------------------
HRESULT             InitWindow( HINSTANCE hInstance, int nCmdShow );
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
HRESULT				Render(float deltaTime, ShaderDefinitions &shader);
HRESULT				Update(float deltaTime);
Vertex*				CreateBox(int size, D3DXVECTOR3 center);
void				UpdateMovement(float p_dt);
void				CreateShaders(int threadsX, int threadsY, int threadsZ, int groupsX,
								  int groupsY, int groupsZ, int bounces, int lights);


char* FeatureLevelToString(D3D_FEATURE_LEVEL featureLevel)
{
	if(featureLevel == D3D_FEATURE_LEVEL_11_0)
		return "11.0";
	if(featureLevel == D3D_FEATURE_LEVEL_10_1)
		return "10.1";
	if(featureLevel == D3D_FEATURE_LEVEL_10_0)
		return "10.0";

	return "Unknown";
}

//--------------------------------------------------------------------------------------
// Create Direct3D device and swap chain
//--------------------------------------------------------------------------------------
HRESULT Init()
{
#pragma region Template

	HRESULT hr = S_OK;;

	RECT rc;
	GetClientRect( g_hWnd, &rc );
	g_Width = rc.right - rc.left;;
	g_Height = rc.bottom - rc.top;

	UINT createDeviceFlags = 0;
#ifdef _DEBUG
	createDeviceFlags |= D3D11_CREATE_DEVICE_DEBUG;
#endif

	D3D_DRIVER_TYPE driverType;

	D3D_DRIVER_TYPE driverTypes[] = 
	{
		D3D_DRIVER_TYPE_HARDWARE,
		D3D_DRIVER_TYPE_REFERENCE,
	};
	UINT numDriverTypes = sizeof(driverTypes) / sizeof(driverTypes[0]);

	DXGI_SWAP_CHAIN_DESC sd;
	ZeroMemory( &sd, sizeof(sd) );
	sd.BufferCount = 1;
	sd.BufferDesc.Width = g_Width;
	sd.BufferDesc.Height = g_Height;
	sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
	sd.BufferDesc.RefreshRate.Numerator = 60;
	sd.BufferDesc.RefreshRate.Denominator = 1;
	sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT | DXGI_USAGE_UNORDERED_ACCESS;
	sd.OutputWindow = g_hWnd;
	sd.SampleDesc.Count = 1;
	sd.SampleDesc.Quality = 0;
	sd.Windowed = TRUE;

	D3D_FEATURE_LEVEL featureLevelsToTry[] = {
		D3D_FEATURE_LEVEL_11_0,
		D3D_FEATURE_LEVEL_10_1,
		D3D_FEATURE_LEVEL_10_0
	};
	D3D_FEATURE_LEVEL initiatedFeatureLevel;

	for( UINT driverTypeIndex = 0; driverTypeIndex < numDriverTypes; driverTypeIndex++ )
	{
		driverType = driverTypes[driverTypeIndex];
		hr = D3D11CreateDeviceAndSwapChain(
			NULL,
			driverType,
			NULL,
			createDeviceFlags,
			featureLevelsToTry,
			ARRAYSIZE(featureLevelsToTry),
			D3D11_SDK_VERSION,
			&sd,
			&g_SwapChain,
			&g_Device,
			&initiatedFeatureLevel,
			&g_DeviceContext);

		if( SUCCEEDED( hr ) )
		{
			char title[256];
			sprintf_s(
				title,
				sizeof(title),
				"BTH - Direct3D 11.0 Template | Direct3D 11.0 device initiated with Direct3D %s feature level",
				FeatureLevelToString(initiatedFeatureLevel)
			);
			SetWindowText(g_hWnd, title);

			break;
		}
	}
	if( FAILED(hr) )
		return hr;

	// Create a render target view
	ID3D11Texture2D* pBackBuffer;
	hr = g_SwapChain->GetBuffer( 0, __uuidof( ID3D11Texture2D ), (LPVOID*)&pBackBuffer );
	if( FAILED(hr) )
		return hr;

	// create shader unordered access view on back buffer for compute shader to write into texture
	hr = g_Device->CreateUnorderedAccessView( pBackBuffer, NULL, &g_BackBufferUAV );

	//create helper sys and compute shader instance
	g_ComputeSys = new ComputeWrap(g_Device, g_DeviceContext);
	//g_ComputeShader = g_ComputeSys->CreateComputeShader(_T("BasicCompute.fx"), NULL, "main", NULL);
	g_Timer = new D3D11Timer(g_Device, g_DeviceContext);

	//END OF TEMPLATE CODE
	#pragma endregion Default code

	//BEGIN OF OWN CODE

	g_camera = new Camera(D3DXVECTOR3(0,0,-90));
	g_camera->createProjectionMatrix(0.4f*PI, (float)g_Width/g_Height, 1.0f, 1000.0f);
	g_camera->setViewMatrix(g_camera->getPosition());
	g_mouseInput = new MouseInput(g_hWnd, g_camera, g_Width, g_Height);

	//ConstantBuffer
	g_cBuffer = new Buffer();
	
	g_cData.camPos = g_camera->getPosition();
	g_cData.fovX = g_camera->getFOV();
	g_cData.fovY = g_camera->getFOV();
	D3DXMATRIX viewInv;
	D3DXMatrixInverse(&viewInv,NULL, &g_camera->getViewMatrix());
	D3DXMATRIX projInv;
	D3DXMatrixInverse(&projInv,NULL, &g_camera->getProjectionMatrix());
	g_cData.WVP = g_camera->getViewMatrix() * g_camera->getProjectionMatrix();
	g_cData.projMatInv = projInv;
	g_cData.viewMatInv = viewInv;
	g_cData.screenHeight = g_Height;
	g_cData.screenWidth = g_Width;

	BufferInitDesc desc;
	desc.initData = &g_cData;
	desc.elementSize = sizeof(cData);
	desc.numElements = 1;
	desc.type = CONSTANT_BUFFER_CS;
	desc.usage = BUFFER_DEFAULT;

	g_cBuffer->init(g_Device, g_DeviceContext, desc);
	g_DeviceContext->UpdateSubresource(g_cBuffer->getBufferPointer(), 0, NULL, &g_cData, 0, 0);
	g_cBuffer->apply(0);


	g_loader = new Loader("obj//");
	g_loader->loadFile("sf.obj");

	//Get loaded materials
	vector<OBJMaterial> materialList;
	OBJMaterial	material;
	for(int i = 0; i <= g_loader->getMaterialId(); i++)
	{
		material.Ka = D3DXVECTOR4(g_loader->GetMaterialAt(i).Ka,1);
		material.Kd = D3DXVECTOR4(g_loader->GetMaterialAt(i).Kd,1);
		material.Ks = D3DXVECTOR4(g_loader->GetMaterialAt(i).Ks,g_loader->GetMaterialAt(i).Ns);
		material.Ni = g_loader->GetMaterialAt(i).Ni;
		materialList.push_back(material);
	}

	D3DXMatrixScaling(&g_cData.scale, 1.0f,1.0f,1.0f);
	g_DeviceContext->UpdateSubresource(g_cBuffer->getBufferPointer(), 0, NULL, &g_cData, 0, 0);


	OctTree tree;
	//Creates the tree and removes unused nodes
	tree.CreateTree( g_loader->getVertices().data(), g_loader->getVertices().size());

	//Organize data for the shaders
	std::vector<OBJVertex> vertices;
	vertices.reserve(g_loader->getVertices().size());
	std::vector<HLSLNode> HLnodes;
	tree.OrganizeData(vertices, HLnodes, g_loader->getVertices().data());

	//Primary rays
	g_rayBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(Ray),g_Height*g_Width, true, true, NULL,true, "Structured Buffer:Rays");

	//IntersectionStage
	Vertex* box = CreateBox(40,D3DXVECTOR3(0,0,0));

	g_ObjectBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(Vertex),36, true, false, box,false, "Structured Buffer:BOXVertex");
	g_OctTreeBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(HLSLNode), HLnodes.size(), true, false,HLnodes.data(),false, "Structured Buffer:OctTreeBuffer");
	g_OctTriangleBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(OBJVertex),vertices.size(), true, false, vertices.data(),false, "Structured Buffer:OctVertices");
	g_hitDataBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(HitData),g_Height*g_Width, true, true, NULL,true, "Structured Buffer:HitData");

	D3DX11CreateShaderResourceViewFromFile(g_Device, g_loader->GetMaterialAt(0).map_Kd,NULL,NULL,&g_objTexture, &hr);

	//ColorStage
	g_lightBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(Light),sizeof(g_lights)/sizeof(Light), true, false, &g_lights,true, "Structured Buffer:Light");
	g_accColorBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(D3DXVECTOR4),g_Height*g_Width, true, true, NULL,true, "Structured Buffer:accColor");
	g_materialBuffer = g_ComputeSys->CreateBuffer(STRUCTURED_BUFFER, sizeof(OBJMaterial),materialList.size(), true, false, materialList.data(),false, "Structured Buffer:OBJMaterail");
	
	//CreateShaders(4,4,1,100,100,1,0,1);
	delete box;

#ifdef TEST

	for(int i = (int)(32 * ((float)RESOLUTION / 800)); i % 2 == 0 && i > 0; i = (int)(i * 0.5f))
	{
		int groups = (int)((float)RESOLUTION/i);
		CreateShaders(i,i,1,groups,groups,1,0,1);
		CreateShaders(i,i,1,groups,groups,1,10,10);
		CreateShaders(i,i,1,groups,groups,1,10,1);
		CreateShaders(i,i,1,groups,groups,1,0,10);
		CreateShaders(i,i,1,groups,groups,1,5,5);
	}
#else
	CreateShaders(2,2,1,200,200,1,0,2);
#endif

	return S_OK;
}

HRESULT Update(float deltaTime)
{
	UpdateMovement( deltaTime);
	g_camera->updateCameraPos();
	g_camera->updateViewMatrix();
	
	//Update constantbuffer
	g_cData.camPos = g_camera->getPosition();
	D3DXMATRIX viewInv;
	D3DXMatrixInverse(&viewInv,NULL, &g_camera->getViewMatrix());
	D3DXMATRIX projInv;
	D3DXMatrixInverse(&projInv,NULL, &g_camera->getProjectionMatrix());
	D3DXMATRIX WVP = g_camera->getViewMatrix() * g_camera->getProjectionMatrix();
	g_cData.WVP = WVP;
	g_cData.projMatInv = projInv;
	g_cData.viewMatInv = viewInv;

	//Lights movement
	//for(int i = 0; i < 10; i++)
	//{
	//	if(i%2 == 0)
	//	{
	//		g_lights[i].position.y += g_lightSpeed * deltaTime;
	//	}
	//	else
	//	{
	//		g_lights[i].position.y -= g_lightSpeed * deltaTime;
	//	}
	//}
	//if(g_lights[0].position.y < -10 || g_lights[0].position.y > 10)
	//{
	//	g_lightSpeed *= -1;
	//}
	return S_OK;
}

HRESULT Render(float deltaTime, ShaderDefinitions &shader)
{
	g_DeviceContext->UpdateSubresource(g_cBuffer->getBufferPointer(), 0, NULL, &g_cData, 0, 0);
	g_cBuffer->apply(0);
	
	static ID3D11UnorderedAccessView* clearuav[] = { 0,0,0,0,0,0,0 };
	static ID3D11ShaderResourceView* clearsrv[]	= { 0,0,0,0,0,0,0 };

	static ID3D11ShaderResourceView* bufftri[] = { 
		g_ObjectBuffer->GetResourceView(),
		g_OctTreeBuffer->GetResourceView(),
		g_OctTriangleBuffer->GetResourceView(),
		g_objTexture};

	static ID3D11UnorderedAccessView* uavrays[]	= { 
		g_rayBuffer->GetUnorderedAccessView(),
		g_hitDataBuffer->GetUnorderedAccessView(),
		g_BackBufferUAV,
		g_accColorBuffer->GetUnorderedAccessView()};

	static ID3D11UnorderedAccessView* uav[]	= { 
		g_BackBufferUAV,
		g_accColorBuffer->GetUnorderedAccessView()};

	static ID3D11UnorderedAccessView* intersectionBuffer[] = {
		g_rayBuffer->GetUnorderedAccessView(),
		g_hitDataBuffer->GetUnorderedAccessView()};
	
	static ID3D11ShaderResourceView* colorBuffer[] = {	
		g_ObjectBuffer->GetResourceView(),
		g_hitDataBuffer->GetResourceView(),
		g_lightBuffer->GetResourceView(),
		g_OctTreeBuffer->GetResourceView(),
		g_OctTriangleBuffer->GetResourceView(),
		g_materialBuffer->GetResourceView()};

	// ### PRIMARY RAY ###
	g_DeviceContext->CSSetUnorderedAccessViews(0, 4, uavrays, NULL);

	shader.CS_ComputeRay->Set();
	g_Timer->Start();		
	g_DeviceContext->Dispatch( std::atoi(shader.noDGroupsX.c_str()), std::atoi(shader.noDGroupsY.c_str()), std::atoi(shader.noDGroupsZ.c_str()) );
	g_Timer->Stop();
	shader.CS_ComputeRay->Unset();
	////Clear used resources
	g_DeviceContext->CSSetUnorderedAccessViews(0, 4, clearuav, NULL);
	// ### PRIMARY RAY END ###
	shader.avgCompRay = (shader.avgCompRay + (float)g_Timer->GetTime()) * 0.5f;

	/*PointLight* lightPointer =  g_lightBuffer->Map<PointLight>();

	memcpy(lightPointer, g_lights, sizeof(PointLight)*sizeof(g_lights)/sizeof(PointLight));
	g_lightBuffer->Unmap();
	g_lightBuffer->CopyToResource();*/

	unsigned int bounces = std::atoi(shader.BOUNCES.c_str());
	for(unsigned int i = 0; i <= bounces; i++)
	{
		// ### IntersectionStage ###		
		g_DeviceContext->CSSetShaderResources(0,4,bufftri);
		g_DeviceContext->CSSetUnorderedAccessViews(0, 2, intersectionBuffer, NULL);
		shader.CS_IntersectionStage->Set();
		g_Timer->Start();
		g_DeviceContext->Dispatch( std::atoi(shader.noDGroupsX.c_str()), std::atoi(shader.noDGroupsY.c_str()), std::atoi(shader.noDGroupsZ.c_str()) );
		g_Timer->Stop();
		shader.CS_IntersectionStage->Unset();
		//Clear used resources
		g_DeviceContext->CSSetUnorderedAccessViews(0, 2, clearuav, NULL);
		g_DeviceContext->CSSetShaderResources(0,4,clearsrv);
		// ### IntersectionStage END ###
		shader.avgIntersect = (shader.avgIntersect + (float)g_Timer->GetTime()) * 0.5f;
		// ### ColorStage ###
		g_DeviceContext->CSSetShaderResources(0,6,colorBuffer);		
		g_DeviceContext->CSSetUnorderedAccessViews(0, 2, uav, NULL);

		shader.CS_ColorStage->Set();
		g_Timer->Start();
		g_DeviceContext->Dispatch( std::atoi(shader.noDGroupsX.c_str()), std::atoi(shader.noDGroupsY.c_str()), std::atoi(shader.noDGroupsZ.c_str()) );
		g_Timer->Stop();
		shader.CS_ColorStage->Unset();
		//Clear used resources
		g_DeviceContext->CSSetShaderResources(0,6,clearsrv);		
		g_DeviceContext->CSSetUnorderedAccessViews(0, 2, clearuav, NULL);
		// ### ColorStage END ###
		shader.avgColor = (shader.avgColor + (float)g_Timer->GetTime()) * 0.5f;
	}

	if(FAILED(g_SwapChain->Present( 0, 0 )))
		return E_FAIL;
	
	return S_OK;
}

void UpdateMovement(float p_dt)
{
	if(GetAsyncKeyState('A') & 0x8000)
	{
		g_camera->strafe(-g_cameraSpeed * p_dt );
	}
	if(GetAsyncKeyState('D') & 0x8000)
	{
		g_camera->strafe( g_cameraSpeed * p_dt );
	}
	if(GetAsyncKeyState('W') & 0x8000)
	{
		g_camera->walk( g_cameraSpeed * p_dt );
	}
	if(GetAsyncKeyState('S') & 0x8000)
	{
		g_camera->walk( -g_cameraSpeed * p_dt );
	}
	if(GetAsyncKeyState('C') & 0x8000)
	{
		if(g_mouseInput->getMode())
			g_mouseInput->changeToPointerMode();
		else
			g_mouseInput->changeToFPSMode();
	}
}

//--------------------------------------------------------------------------------------
// Entry point to the program. Initializes everything and goes into a message processing 
// loop. Idle time is used to render the scene.
//--------------------------------------------------------------------------------------
int WINAPI wWinMain( HINSTANCE hInstance, HINSTANCE hPrevInstance, LPWSTR lpCmdLine, int nCmdShow )
{
	if( FAILED( InitWindow( hInstance, nCmdShow ) ) )
		return EXIT_FAILURE;

	if( FAILED( Init() ) )
		return EXIT_FAILURE;

	__int64 cntsPerSec = 0;
	QueryPerformanceFrequency((LARGE_INTEGER*)&cntsPerSec);
	float secsPerCnt = 1.0f / (float)cntsPerSec;

	__int64 prevTimeStamp = 0;
	QueryPerformanceCounter((LARGE_INTEGER*)&prevTimeStamp);

	// Main message loop
	if(g_Shaders.empty())
		return EXIT_FAILURE;

#ifdef TEST
	for( auto &shader : g_Shaders)
	{
		float timer = 0.f;

		while(timer < 5)
		{
			__int64 currTimeStamp = 0;
			QueryPerformanceCounter((LARGE_INTEGER*)&currTimeStamp);
			float dt = (currTimeStamp - prevTimeStamp) * secsPerCnt;

			//render
			Update(dt);
			Render(dt, shader);

			prevTimeStamp = currTimeStamp;

			timer += dt;//shader.avgCompRay + shader.avgIntersect + shader.avgColor;
		}
	}

	ofstream myfile("testsOctIncColorTEST2.txt");
	if(myfile.is_open())
	{
		myfile << "TESTS " << RESOLUTION << "x" << RESOLUTION << "\n";
		myfile << "-------------------------------------\n";
		for( auto &shader : g_Shaders)
		{
			myfile << "Threads(" << shader.noThreadsX << ","
				<< shader.noThreadsY << ","
				<< shader.noThreadsZ << ") ";
			myfile << "Groups(" << shader.noDGroupsX << ","
				<< shader.noDGroupsY << ","
				<< shader.noDGroupsZ << ")\n";
			myfile << "Bounces: " << shader.BOUNCES << ", "
				<< "Lights: " << shader.LIGHTS << ".\n\n";
			myfile << "Average RayCreation: \t\t" << shader.avgCompRay << " Milliseconds.\n";
			myfile << "Average IntersectionStage: \t" << shader.avgIntersect << " Milliseconds.\n";
			myfile << "Average ColorStage: \t\t" << shader.avgColor << " Milliseconds.\n";
			myfile << "-------------------------------------\n";

		}
	}
	myfile.close();

	return EXIT_SUCCESS;
#else
	MSG msg = {0};

	while(WM_QUIT != msg.message)
	{
		if( PeekMessage( &msg, NULL, 0, 0, PM_REMOVE) )
		{
			TranslateMessage( &msg );
			DispatchMessage( &msg );
		}
		else
		{
			__int64 currTimeStamp = 0;
			QueryPerformanceCounter((LARGE_INTEGER*)&currTimeStamp);
			float dt = (currTimeStamp - prevTimeStamp) * secsPerCnt;

			//render
			Update(dt);
			Render(dt, g_Shaders.front());

			prevTimeStamp = currTimeStamp;
		}
	}
	return (int) msg.wParam;
#endif
}


//--------------------------------------------------------------------------------------
// Register class and create window
//--------------------------------------------------------------------------------------
HRESULT InitWindow( HINSTANCE hInstance, int nCmdShow )
{
	// Register class
	WNDCLASSEX wcex;
	wcex.cbSize = sizeof(WNDCLASSEX); 
	wcex.style          = CS_HREDRAW | CS_VREDRAW;
	wcex.lpfnWndProc    = WndProc;
	wcex.cbClsExtra     = 0;
	wcex.cbWndExtra     = 0;
	wcex.hInstance      = hInstance;
	wcex.hIcon          = 0;
	wcex.hCursor        = LoadCursor(NULL, IDC_ARROW);
	wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
	wcex.lpszMenuName   = NULL;
	wcex.lpszClassName  = "BTH_D3D_Template";
	wcex.hIconSm        = 0;
	if( !RegisterClassEx(&wcex) )
		return E_FAIL;

	// Create window
	g_hInst = hInstance; 
	RECT rc = { 0, 0, RESOLUTION, RESOLUTION };
	AdjustWindowRect( &rc, WS_OVERLAPPEDWINDOW, FALSE );
	
	if(!(g_hWnd = CreateWindow(
							"BTH_D3D_Template",
							"BTH - Direct3D 11.0 Template",
							WS_OVERLAPPEDWINDOW,
							CW_USEDEFAULT,
							CW_USEDEFAULT,
							rc.right - rc.left,
							rc.bottom - rc.top,
							NULL,
							NULL,
							hInstance,
							NULL)))
	{
		return E_FAIL;
	}

	ShowWindow( g_hWnd, nCmdShow );

	return S_OK;
}


//--------------------------------------------------------------------------------------
// Called every time the application receives a message
//--------------------------------------------------------------------------------------
LRESULT CALLBACK WndProc( HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam )
{
	PAINTSTRUCT ps;
	HDC hdc;

	UINT dwSize;
	RAWINPUT* raw;

	switch (message) 
	{
	case WM_PAINT:
		hdc = BeginPaint(hWnd, &ps);
		EndPaint(hWnd, &ps);
		break;

	case WM_DESTROY:
		PostQuitMessage(0);
		break;

	case WM_KEYDOWN:

		switch(wParam)
		{
			case VK_ESCAPE:
				PostQuitMessage(0);//g_ShouldQuit = true;//
				break;
		}
		break;

	case WM_INPUT:
			dwSize = 40;
			static BYTE lpb[40];
    
			GetRawInputData( (HRAWINPUT)lParam, RID_INPUT, 
							lpb, &dwSize, sizeof(RAWINPUTHEADER) );
    
			raw = (RAWINPUT*)lpb;
    
			if (raw->header.dwType == RIM_TYPEMOUSE) 
			{
				if (g_mouseInput->getMode())
				{
					g_mouseInput->rawUpdate(raw);
					g_mouseInput->moveCursorToCenter();
					g_mouseInput->notifyObservers();
				}

				else
				{
					g_mouseInput->updateMousePos(lParam);
				}
			}
			break;

	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}

	return 0;
}

Vertex* CreateBox(int size, D3DXVECTOR3 center)
{
	Vertex* box = new Vertex[36];
	D3DXVECTOR4 color;
	D3DXVECTOR3 vert0 = center + D3DXVECTOR3(-1.0f*size, -1.0f*size, -1.0f*size); // 0 --- LowerLeftFront
	D3DXVECTOR3 vert1 = center + D3DXVECTOR3( 1.0f*size, -1.0f*size, -1.0f*size); // 1 +-- LowerRightFront
	D3DXVECTOR3 vert2 = center + D3DXVECTOR3(-1.0f*size,  1.0f*size, -1.0f*size); // 2 -+- UpperLeftFront
	D3DXVECTOR3 vert3 = center + D3DXVECTOR3( 1.0f*size,  1.0f*size, -1.0f*size); // 3 ++- UpperRightFront
	D3DXVECTOR3 vert4 = center + D3DXVECTOR3(-1.0f*size, -1.0f*size,  1.0f*size); // 4 --+ LowerLeftBack
	D3DXVECTOR3 vert5 = center + D3DXVECTOR3( 1.0f*size, -1.0f*size,  1.0f*size); // 5 +-+ LowerRightBack
	D3DXVECTOR3 vert6 = center + D3DXVECTOR3(-1.0f*size,  1.0f*size,  1.0f*size); // 6 -++ UpperLeftBack
	D3DXVECTOR3 vert7 = center + D3DXVECTOR3( 1.0f*size,  1.0f*size,  1.0f*size); // 7 +++ UpperRightBack
												 
	// Back
	color = D3DXVECTOR4(0,1,0,1);
	box[0] = CreateVertex(vert4, color, 1, 0.2f);
	box[1] = CreateVertex(vert6, color, 1, 0.2f);
	box[2] = CreateVertex(vert5, color, 1, 0.2f);
	box[3] = CreateVertex(vert6, color, 2, 0.2f);
	box[4] = CreateVertex(vert7, color, 2, 0.2f);
	box[5] = CreateVertex(vert5, color, 2, 0.2f);

	// Front
	/*box[6] = CreateVertex(vert1, color, 3, 0.2f);
	box[7] = CreateVertex(vert3, color, 3, 0.2f);
	box[8] = CreateVertex(vert0, color, 3, 0.2f);
	box[9] = CreateVertex(vert3, color, 4, 0.2f);
	box[10] = CreateVertex(vert2, color, 4, 0.2f);
	box[11] = CreateVertex(vert0, color, 4, 0.2f);*/

	// Top
	box[12] = CreateVertex(vert3, color, 5, 0.2f);
	box[13] = CreateVertex(vert7, color, 5, 0.2f);
	box[14] = CreateVertex(vert2, color, 5, 0.2f);
	box[15] = CreateVertex(vert7, color, 6, 0.2f);
	box[16] = CreateVertex(vert6, color, 6, 0.2f);
	box[17] = CreateVertex(vert2, color, 6, 0.2f);

	// Bottom
	box[18] = CreateVertex(vert0, color, 7, 0.2f);
	box[19] = CreateVertex(vert4, color, 7, 0.2f);
	box[20] = CreateVertex(vert1, color, 7, 0.2f);
	box[21] = CreateVertex(vert4, color, 8, 0.2f);
	box[22] = CreateVertex(vert5, color, 8, 0.2f);
	box[23] = CreateVertex(vert1, color, 8, 0.2f);

	// Right 
	box[24] = CreateVertex(vert5, color, 9, 0.2f);
	box[25] = CreateVertex(vert7, color, 9, 0.2f);
	box[26] = CreateVertex(vert1, color, 9, 0.2f);
	box[27] = CreateVertex(vert7, color, 10, 0.2f);
	box[28] = CreateVertex(vert3, color, 10, 0.2f);
	box[29] = CreateVertex(vert1, color, 10, 0.2f);

	// Left
	box[30] = CreateVertex(vert0, color, 11, 0.2f);
	box[31] = CreateVertex(vert2, color, 11, 0.2f);
	box[32] = CreateVertex(vert4, color, 11, 0.2f);
	box[33] = CreateVertex(vert2, color, 12, 0.2f);
	box[34] = CreateVertex(vert6, color, 12, 0.2f);
	box[35] = CreateVertex(vert4, color, 12, 0.2f);


	return box;
}

void CreateShaders(int threadsX, int threadsY, int threadsZ, int groupsX,
	int groupsY, int groupsZ, int bounces, int lights)
{
	g_Shaders.push_back(ShaderDefinitions());
	
	g_Shaders.back().noThreadsX = std::to_string(threadsX);
	g_Shaders.back().noThreadsY = std::to_string(threadsY);
	g_Shaders.back().noThreadsZ = std::to_string(threadsZ);
	g_Shaders.back().noDGroupsX = std::to_string(groupsX);
	g_Shaders.back().noDGroupsY = std::to_string(groupsY);
	g_Shaders.back().noDGroupsZ = std::to_string(groupsZ);
	g_Shaders.back().BOUNCES = std::to_string(bounces);
	g_Shaders.back().LIGHTS = std::to_string(lights);

	D3D_SHADER_MACRO Shader_Macros[] = {"noThreadsX", g_Shaders.back().noThreadsX.c_str(),
		"noThreadsY",  g_Shaders.back().noThreadsY.c_str(),
		"noThreadsZ",  g_Shaders.back().noThreadsZ.c_str(),
		"noDGroupsX",  g_Shaders.back().noDGroupsX.c_str(),
		"noDGroupsY",  g_Shaders.back().noDGroupsY.c_str(),
		"noDGroupsZ",  g_Shaders.back().noThreadsZ.c_str(),
		"BOUNCES",  g_Shaders.back().BOUNCES.c_str(),
		"LIGHTS",  g_Shaders.back().LIGHTS.c_str(),
		NULL,NULL};

	//Primary rays
	g_Shaders.back().CS_ComputeRay = g_ComputeSys->CreateComputeShader(_T("PrimaryRayCompute.fx"), NULL, "main", Shader_Macros);

	//IntersectionStage
	g_Shaders.back().CS_IntersectionStage = g_ComputeSys->CreateComputeShader(_T("IntersectionStageCOmpute.fx"), NULL, "main", Shader_Macros);

	//ColorStage
	g_Shaders.back().CS_ColorStage = g_ComputeSys->CreateComputeShader(_T("ColorStageCompute.fx"), NULL, "main", Shader_Macros);

	if(!g_Shaders.back().CS_ComputeRay || !g_Shaders.back().CS_IntersectionStage || !g_Shaders.back().CS_ColorStage)
		g_Shaders.pop_back();
}