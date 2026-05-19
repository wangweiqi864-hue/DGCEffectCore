//  BEShaderTypes.h
//  BECore


#ifndef BEShaderTypes_h
#define BEShaderTypes_h

#import <simd/simd.h>

typedef struct
{
    vector_float4 position;
    packed_float2 texCoord;
} DGCBEVertex;

typedef enum BEBufferIndex
{
    BEBufferIndexVertices = 0,
    BEBufferIndexUniforms = 1,
} BEVertexInputIndex;

typedef enum BETextureIndex
{
    BETextureIndexBaseMap = 0,
} BETextureIndex;

typedef struct
{
    matrix_float4x4 mvp;
} BEUniforms;

#endif /* BEShaderTypes_h */
