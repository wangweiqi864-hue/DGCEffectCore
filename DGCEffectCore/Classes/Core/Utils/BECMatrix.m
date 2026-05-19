//  BEMatrix4f.m
//  Core

#import <Foundation/Foundation.h>
#import "BECMatrix.h"

void transpose(float *matrix, int dim) {
    for (int i = 0; i < dim; ++ i) {
        for (int j = 0; j < i; ++j ) {
            float tmp = matrix[i*dim + j];
            matrix[i*dim + j] = matrix[j*dim + i];
            matrix[j*dim + i] = tmp;
        }
    }
}

void identity(float* mat, int dim) {
    memset(mat, 0, dim * dim * sizeof(float));
    for (int i = 0; i < dim; ++i) {
        mat[i*dim + i] = 1.0;
    }
}

void getProjectionMatrixByCameraIntrinsic(float* mat, float fx, float fy, float cx, float cy, float width, float height, float zNear, float zFar) {
    float a = -(zFar + zNear) / (zFar - zNear);
    float b = -(2.0 * zNear * zFar) / (zFar - zNear);
    float tmp[16] = {
        (2.0f * fx) / width  , 0.0f                  , 1.0f - 2.0f * cx / width   , 0.0f
        , 0.0f               , (2.0f * fy) / height  , 2.0f * cy / height - 1.0   , 0.0f
        , 0.0f               , 0.0f                  , a                          , b
        , 0.0f               , 0.0f                  , -1.0f                      , 0.0f
    };
    memcpy(mat, tmp, 16 * sizeof(float));
}

// only valid when dimension equals 4, Ret = A * B
void matMultiply(float* Ret, float* A, float* B, int dim) {
    assert(dim == 4);
    float* C = Ret;
    C[0] = A[0] * B[0] + A[1] * B[4] + A[2] * B[8] + A[3] * B[12];
    C[1] = A[0] * B[1] + A[1] * B[5] + A[2] * B[9] + A[3] * B[13];
    C[2] = A[0] * B[2] + A[1] * B[6] + A[2] * B[10] + A[3] * B[14];
    C[3] = A[0] * B[3] + A[1] * B[7] + A[2] * B[11] + A[3] * B[15];
    
    C[4] = A[4] * B[0] + A[5] * B[4] + A[6] * B[8] + A[7] * B[12];
    C[5] = A[4] * B[1] + A[5] * B[5] + A[6] * B[9] + A[7] * B[13];
    C[6] = A[4] * B[2] + A[5] * B[6] + A[6] * B[10] + A[7] * B[14];
    C[7] = A[4] * B[3] + A[5] * B[7] + A[6] * B[11] + A[7] * B[15];
    
    C[8] = A[8] * B[0] + A[9] * B[4] + A[10] * B[8] + A[11] * B[12];
    C[9] = A[8] * B[1] + A[9] * B[5] + A[10] * B[9] + A[11] * B[13];
    C[10] = A[8] * B[2] + A[9] * B[6] + A[10] * B[10] + A[11] * B[14];
    C[11] = A[8] * B[3] + A[9] * B[7] + A[10] * B[11] + A[11] * B[15];
    
    C[12] = A[12] * B[0] + A[13] * B[4] + A[14] * B[8] + A[15] * B[12];
    C[13] = A[12] * B[1] + A[13] * B[5] + A[14] * B[9] + A[15] * B[13];
    C[14] = A[12] * B[2] + A[13] * B[6] + A[14] * B[10] + A[15] * B[14];
    C[15] = A[12] * B[3] + A[13] * B[7] + A[14] * B[11] + A[15] * B[15];
}

void constructMatrixByRT(float* ret, float* R, float* T) {
    identity(ret, 4);
    ret[0] = R[0]; ret[1] = R[1]; ret[2] = R[2]; ret[3] = T[0];
    ret[4] = R[3]; ret[5] = R[4]; ret[6] = R[5]; ret[7] = T[1];
    ret[8] = R[6]; ret[9] = R[7]; ret[10] = R[8]; ret[11] = T[2];
}
