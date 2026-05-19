//  BEModelUtils.h
//  BECore


#ifndef BEModelUtils_h
#define BEModelUtils_h

#import <Foundation/Foundation.h>

@interface DGCBEVec2: NSObject
@property float X;
@property float Y;
@end

@interface DGCBEVec3 : NSObject
@property float X;
@property float Y;
@property float Z;
@end


@interface DGCBEVertex : NSObject
@property DGCBEVec3 *Position;
@property DGCBEVec2 *TextureCoordinate;
@property DGCBEVec3 *Normal;
@end


@interface DGCBEMaterial : NSObject
// Material Name
@property NSString* name;
// Ambient Color
@property DGCBEVec3* Ka;
// Diffuse Color
@property DGCBEVec3* Kd;
// Specular Color
@property DGCBEVec3* Ks;
// Specular Exponent
@property float Ns;
// Optical Density
@property float Ni;
// Dissolve
@property float d;
// Illumination
@property int illum;
// Ambient Texture Map
@property NSString* map_Ka;
// Diffuse Texture Map
@property NSString* map_Kd;
// Specular Texture Map
@property NSString* map_Ks;
// Specular Hightlight Map
@property NSString* map_Ns;
// Alpha Texture Map
@property NSString* map_d;
// Bump Map
@property NSString* map_bump;
@end


@interface DGCBEMesh : NSObject
@property NSString *MeshName;
@property NSArray<DGCBEVertex *> *Vertices;
@property NSArray<NSNumber *> *Indices;
@property DGCBEMaterial* MeshMaterial;
@end


@interface DGCBEOBJModelLoader : NSObject

- (BOOL)LoadFile:(NSString*)path;
- (float*)GetVertices;
- (unsigned long)GetVerticesSize;
- (unsigned short*)GetIndices;
- (unsigned long)GetIndicesSize;

@property NSMutableArray<DGCBEMesh *> *meshes;

@end

#endif /* BEModelUtils_h */
