//  DGCBEAdaptiveSharpenTask.h
// EffectsARSDK


#ifndef BEAdaptiveSharpenTask_h
#define BEAdaptiveSharpenTask_h

#import "DGCBEAlgorithmTask.h"

@protocol BEAdaptiveSharpenResourceProvider <NSObject>

- (NSString *)licensePath;

@end

@interface DGCBEAdaptiveSharpenTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int) initTask;
-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
-(int)destroyTask;
@end

#endif /* BeLensVideoSR_h */
