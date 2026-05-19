//  DGCBEVideoFrameInsertTask.h
//  BECore


#ifndef BEVideoFrameInsertTask_h
#define BEVideoFrameInsertTask_h

#import <CoreVideo/CoreVideo.h>
#import "DGCBEAlgorithmTask.h"

@interface DGCBEVideoFrameInsertTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int) initTask;
-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)frontBuffer nextCVPixelBuffer:(CVPixelBufferRef)backBuffer withRatio:(float)ratio Update:(bool)update;
-(int) destroyTask;

@end

#endif /* BEVideoFrameInsertTask_h */
