#ifndef HID_USAGE_PAGE_GENERIC
#define HID_USAGE_PAGE_GENERIC         ((USHORT) 0x01)
#endif
#ifndef HID_USAGE_GENERIC_MOUSE
#define HID_USAGE_GENERIC_MOUSE        ((USHORT) 0x02)
#endif

#ifndef MOUSEINPUT_H
#define	MOUSEINPUT_H

#include "stdafx.h"
#include "Camera.h"

class MouseInput
{
public:
	MouseInput( HWND ghWnd,Camera* p_camera, int wndWidth, int wndHeight );
	~MouseInput();
	
	void		rawUpdate( RAWINPUT* raw );
	void		moveCursorToCenter(int p_width, int p_height);
	void		notifyObservers();
	void		setCenterPos(POINT pCenterPos);
	void		setXScale(float f);
	void		setYScale(float f);
	void		resetdXY();

	POINT		getCenterPos();
	int			getLastdX();
	int			getLastdY();
	float		getXScale();
	float		getYScale();

	// NEW
	void		updateMousePos( LPARAM lp );
	void		changeToPointerMode();
	void		changeToFPSMode();
	POINT		getPosition();
	bool		getMode();
	
private:
	POINT			mCenterPos;
	int				x;
	int				y;
	int				dx;
	int				dy;
	float			mXScale;
	float			mYScale;
	bool			fps;
	HWND			mhWnd;
	Camera*			m_camera;
	int				winHeight;
	int				winWidth;
};
#endif MOUSEINPUT_H