//
//  DGCBEVideoLiteHdrTask.h
//  Core
//

#ifndef BEVideoLiteHdrTask_h
#define BEVideoLiteHdrTask_h

#import "DGCBEAlgorithmTask.h"
#import <CoreVideo/CoreVideo.h>

@protocol BEVideoLiteHdrResourceProvider <NSObject>

- (NSString *)licensePath;
- (const char *)videoHdrLiteHdrPath;

@end

@interface DGCBEVideoLiteHdrTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int) initTask;
-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
-(int)destroyTask;

- (void)resetFirstFrame;
@end

#endif /* BEVideoLiteHdrTask_h */
