#include "Camera.h"

Camera::Camera(D3DXVECTOR3 initPos)
{
	mCameraPos	= initPos;
	mVelocity	= D3DXVECTOR3( 0.0f, 0.0f, 0.0f );

	mRight		= D3DXVECTOR3( 1.0f, 0.0f, 0.0f );
	mUp			= D3DXVECTOR3( 0.0f, 1.0f, 0.0f );
	mLookAt		= D3DXVECTOR3( 0.0f, 0.0f, 1.0f );

	mPitch		= 0.0f;
	mYaw		= 0.0f;
	mLookAtPos	= mCameraPos + mLookAt;

	D3DXMatrixIdentity(&mView);
	D3DXMatrixIdentity(&mProjection);

	MAXpitch	= PI/2;
	MINpitch	= -PI/2;

}

Camera::~Camera(){}

void Camera::createProjectionMatrix( float pFOV, float pAspect,
									float pNearPlane, float pFarPlane )
{
	mFOV		= pFOV;
	mAspect		= pAspect;
	mNearPlane	= pNearPlane;
	mFarPlane	= pFarPlane;

	//float yScale	= cotan( mFOV / 2 );
	//float xScale	= yScale / mAspect;
	float planeDiff	= mFarPlane - mNearPlane;

	// Lens.
	/*mProjection._11 = xScale;
	mProjection._22 = yScale;
	mProjection._33 = mFarPlane / planeDiff;
	mProjection._43 = ( mNearPlane * mFarPlane ) / ( mNearPlane - mFarPlane );
	mProjection._34 = 1.0f;
	mProjection._44 = 0.0f;*/

	//Test
	mProjection._11 = (2* mNearPlane) / mFOV;
	mProjection._22 = (2* mNearPlane) * mAspect;
	mProjection._33 = mFarPlane / planeDiff;
	mProjection._43 = (mNearPlane*mFarPlane) / (mNearPlane - mFarPlane);
	mProjection._34 = 1.0f;
	mProjection._44 = 0.0f;
}

void Camera::updateViewMatrix()
{
	mUp = D3DXVECTOR3(0.0f,1.0f,0.0f);
	mLookAt = D3DXVECTOR3(0.0f,0.0f,1.0f);
	mRight = D3DXVECTOR3(1.0f,0.0f,0.0f);

	D3DXMATRIX R;

	D3DXMatrixRotationAxis(&R, &mRight, mPitch);

	D3DXVec3TransformNormal(&mUp, &mUp, &R);
	D3DXVec3TransformNormal(&mLookAt, &mLookAt, &R);

	D3DXMatrixRotationY(&R, mYaw);

	D3DXVec3TransformNormal(&mUp, &mUp, &R);
	D3DXVec3TransformNormal(&mRight, &mRight, &R);
	D3DXVec3TransformNormal(&mLookAt, &mLookAt, &R);

	// Update view matrix.
	mView._11 = mRight.x; mView._12 = mUp.x; mView._13 = mLookAt.x;
	mView._21 = mRight.y; mView._22 = mUp.y; mView._23 = mLookAt.y;
	mView._31 = mRight.z; mView._32 = mUp.z; mView._33 = mLookAt.z;

	mView._41 = - D3DXVec3Dot( &mCameraPos, &mRight );
	mView._42 = - D3DXVec3Dot( &mCameraPos, &mUp );
	mView._43 = - D3DXVec3Dot( &mCameraPos, &mLookAt );

	mView._14 = 0.0f;
	mView._24 = 0.0f;
	mView._34 = 0.0f;
	mView._44 = 1.0f;
}

void Camera::setViewMatrix(D3DXVECTOR3 pPos)
{
	mUp = D3DXVECTOR3(0.0f,1.0f,0.0f);
	mLookAt = D3DXVECTOR3(0.0f,0.0f,1.0f);
	mRight = D3DXVECTOR3(1.0f,0.0f,0.0f);

	mCameraPos = pPos;

	//mPitch = 40*(PI/180);
	//mYaw = 270*(PI/180);

	D3DXMATRIX R;

	D3DXMatrixRotationAxis(&R, &mRight, mPitch);

	D3DXVec3TransformNormal(&mUp, &mUp, &R);
	D3DXVec3TransformNormal(&mLookAt, &mLookAt, &R);

	D3DXMatrixRotationY(&R, mYaw);

	D3DXVec3TransformNormal(&mUp, &mUp, &R);
	D3DXVec3TransformNormal(&mRight, &mRight, &R);
	D3DXVec3TransformNormal(&mLookAt, &mLookAt, &R);

	// Update view matrix.
	mView._11 = mRight.x; mView._12 = mUp.x; mView._13 = mLookAt.x;
	mView._21 = mRight.y; mView._22 = mUp.y; mView._23 = mLookAt.y;
	mView._31 = mRight.z; mView._32 = mUp.z; mView._33 = mLookAt.z;

	mView._41 = - D3DXVec3Dot( &mCameraPos, &mRight );
	mView._42 = - D3DXVec3Dot( &mCameraPos, &mUp );
	mView._43 = - D3DXVec3Dot( &mCameraPos, &mLookAt );

	mView._14 = 0.0f;
	mView._24 = 0.0f;
	mView._34 = 0.0f;
	mView._44 = 1.0f;
}

void Camera::walk( float f )
{
	D3DXVECTOR3		moveVector( mLookAt.x,0.0f, mLookAt.z );
	D3DXVec3Normalize( &moveVector, &moveVector );
	moveVector *= f;
	mVelocity += moveVector;
}

void Camera::strafe( float f )
{
	mVelocity += mRight * f;
}

void Camera::updateCameraPos()
{
	// Move camera.
	mCameraPos += mVelocity;
	////if(mCameraPos.x < - 100)
	//	mCameraPos.x  = -100;
	////else if(mCameraPos.x > 340)
	//	mCameraPos.x  = 340;

	////if(mCameraPos.z < - 200)
	//	mCameraPos.z  = -200;
	//else if(mCameraPos.z > 200)
	//	mCameraPos.z  = 200;

	mVelocity = D3DXVECTOR3( 0.0f, 0.0f, 0.0f );

	mLookAtPos = mCameraPos + mLookAt;
}

void Camera::setY( float f )
{
	mCameraPos.y += f ;
}

void Camera::updateYaw( float d )
{
	mYaw += d;

	if(mYaw >= 2 * PI)
		mYaw -= 2*PI;
	else if(mYaw <= 0.0f )
		mYaw += 2*PI;
}

void Camera::updatePitch( float d )
{
	if(mPitch < MAXpitch) // Can't pitch up more than MAXpitch.
		mPitch += d;
	else
		mPitch = MAXpitch;

	if(mPitch > MINpitch) // Can't pitch down more than MINpitch.
		mPitch += d;
	else
		mPitch = MINpitch;
}

float Camera::cotan( float d )
{
	return 1 / tan(d);
}

D3DXMATRIX Camera::getProjectionMatrix()
{
	return mProjection;
}

D3DXMATRIX Camera::getViewMatrix()
{
	return mView;
}

D3DXVECTOR3 Camera::getPosition()
{
	return mCameraPos;
}

D3DXVECTOR3 Camera::getLookAt()
{
	return mLookAt;
}

void Camera::setPosition(float x, float y, float z)
{
	mCameraPos = D3DXVECTOR3(x,y,z);
}

float Camera::getFarPlane()
{
	return mFarPlane;
}

float Camera::getFOV()
{
	return mFOV;
}