//  DGCBEOnekeyEnhanceTask.h
//  BECore


#ifndef BEOnekeyEnhanceTask_h
#define BEOnekeyEnhanceTask_h

#import "DGCBEFaceAlgorithmTask.h"
#import <CoreVideo/CoreVideo.h>

@interface DGCBEOnekeyEnhanceTask: NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;
@property (nonatomic, assign) bool inited;

- (int) initTaskWithWidth:(int)width Height:(int)height;
- (CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer withRotation:(int)rotation;
- (int)destroyTask;
- (void)setISOData:(float*)data;
- (void)resetFirstFrame;
@end


#endif /* BEOnekeyEnhanceTask_h */
