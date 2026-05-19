//  DGCBEPhotoNightSceneTask.h
//  Core


#ifndef BEPhotoNightSceneTask_h
#define BEPhotoNightSceneTask_h

#import "DGCBEAlgorithmTask.h"
#import "DGCBEImageUtils.h"
#import "bef_ai_image_quality_enhancement_photo_night_scene.h"

@protocol BEPhotoNightSceneResourceProvider <NSObject>

- (NSString *)licensePath;
-(const char*)skinSegPath;
- (const char *)videoHdrLiteHdrPath;

@end

@interface DGCBEPhotoNightSceneTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;
@property (nonatomic, assign) bool inited;
-(int)initTaskWidth:(int)width height:(int)height imageNum:(int)imageNum;
-(CVPixelBufferRef)processMutilBuffer:(NSArray<NSValue*>*)buffer;
-(int)destroyTask;
@end


#endif /* BEPhotoNightSceneTask_h */
