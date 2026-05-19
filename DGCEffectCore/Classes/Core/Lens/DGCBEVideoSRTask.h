//  BeLensVideoSR.h
// EffectsARSDK


#ifndef BEVideoSRTask_h
#define BEVideoSRTask_h

#import <CoreVideo/CoreVideo.h>
#import "DGCBEAlgorithmTask.h"

@protocol BEVideoSRResourceProvider <NSObject>

- (NSString *)licensePath;
- (NSString *)videoSRModelPath;

@end

@interface DGCBEVideoSRTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int) initTask;
-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
-(int)destroyTask;
@end

#endif /* BeLensVideoSR_h */
