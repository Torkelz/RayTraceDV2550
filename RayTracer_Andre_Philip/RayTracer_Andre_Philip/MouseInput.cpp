#include "MouseInput.h"

MouseInput::MouseInput( HWND ghWnd, Camera* p_camera, int wndWidth, int wndHeight )
{
	RAWINPUTDEVICE Rid[1];
    Rid[0].usUsagePage = HID_USAGE_PAGE_GENERIC; 
    Rid[0].usUsage = HID_USAGE_GENERIC_MOUSE; 
    Rid[0].dwFlags = RIDEV_INPUTSINK;   
    Rid[0].hwndTarget = ghWnd;
	mhWnd = ghWnd;
    RegisterRawInputDevices(Rid, 1, sizeof(Rid[0]));

	ShowCursor(true);
	fps = false;

	dx = 0;
	dy = 0;

	winHeight = wndHeight;
	winWidth = wndWidth;

	mXScale = ( (2 * PI) / (winWidth) );
	mYScale = ( (PI / 3) / winHeight );

	m_camera = p_camera;

	POINT pt;
	pt.x			= winWidth / 2;
	pt.y			= winHeight / 2;

	ClientToScreen(ghWnd, &pt);
	setCenterPos(pt);
}

MouseInput::~MouseInput()
{
}

void MouseInput::rawUpdate(RAWINPUT* raw)
{
	dx = raw->data.mouse.lLastX;
	dy = raw->data.mouse.lLastY;
}

//void MouseInput::moveCursorToCenter(int p_width, int p_height)
void MouseInput::moveCursorToCenter()
{
	POINT pt;
	pt.x			= winWidth / 2;
	pt.y			= winHeight / 2;
	ClientToScreen(mhWnd, &pt);
	SetCursorPos(pt.x, pt.y); 
	//SetCursorPos((int)(p_width * 0.5f), (int)(p_height * 0.5f  )); 
}

void MouseInput::setCenterPos( POINT pCenterPos )
{
	mCenterPos = pCenterPos;
}

POINT MouseInput::getCenterPos()
{
	return mCenterPos;
}

int MouseInput::getLastdX()
{
	return dx;
}

int MouseInput::getLastdY()
{
	return dy;
}

void MouseInput::notifyObservers()
{
	m_camera->updatePitch(dy * mYScale);
	m_camera->updateYaw(dx * mXScale);
}

void MouseInput::resetdXY()
{
	dx = 0;
	dy = 0;
}

void MouseInput::changeToFPSMode()
{
	fps = true;
	ShowCursor(false);
}

void MouseInput::changeToPointerMode()
{
	fps = false;
	ShowCursor(true);
}

void MouseInput::updateMousePos( LPARAM lp )
{
	y = HIWORD( lp );
	x = LOWORD( lp );
}

POINT MouseInput::getPosition()
{
	POINT BAJS;
	GetCursorPos(&BAJS);
	ScreenToClient(mhWnd, &BAJS);

	return BAJS;
}

bool MouseInput::getMode()
{
	return fps;
}