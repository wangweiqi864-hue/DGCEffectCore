//  DGCBETaintSceneDetectTask.h
//  Core


#ifndef BETaintSceneDetectTask_h
#define BETaintSceneDetectTask_h

#import "DGCBEAlgorithmTask.h"
#import <CoreVideo/CoreVideo.h>

@interface DGCBETaintSceneDetectTask : NSObject

@property (nonatomic, assign) float taintScore;
@property (nonatomic, strong) id<BELicenseProvider> provider;

- (int) initTask;
- (int) processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
- (int) destroyTask;

@end

#endif /* BETaintSceneDetectTask_h */
