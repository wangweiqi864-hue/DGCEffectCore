//  BECMatrix.h
//  Core

#ifndef BECMatrix_h
#define BECMatrix_h

// row first stored
void transpose(float *matrix, int dim);
void identity(float* mat, int dim);
void getProjectionMatrixByCameraIntrinsic(float* mat, float fx, float fy, float cx, float cy, float width, float height, float zNear, float zFar);
// only valid when dimension equals 4, Ret = A * B
void matMultiply(float* Ret, float* A, float* B, int dim);
void constructMatrixByRT(float* ret, float* R, float* T);

#endif /* BECMatrix_h */
