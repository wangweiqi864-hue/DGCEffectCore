//  DGCBEVidaTask.h
//  Core


#ifndef BEVidaTask_h
#define BEVidaTask_h

#import <CoreVideo/CoreVideo.h>
#import "DGCBELicenseHelper.h"

@protocol BEVidaResourceProvider <NSObject>

- (const char *)faceModelPath;
- (const char *)aesModelPath;
- (const char *)clarityModelPath;

@end

@interface DGCBEVidaTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int) initTask;
-(int)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
-(int)destroyTask;

-(void)getVidaResult:(float*)face aes:(float*)aes clarity:(float*)clarity;
@end

#endif /* BEVidaTask_h */
