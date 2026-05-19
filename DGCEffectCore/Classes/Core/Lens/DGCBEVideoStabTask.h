//
//  DGCBEVideoStabTask.h
//  Core
//

#ifndef BEVideoStabTask_h
#define BEVideoStabTask_h

#import <CoreVideo/CoreVideo.h>
#import "DGCBELicenseHelper.h"

typedef enum{
    BEVideoStabEstimate,
    BEVideoStabWarp,
}BEVideoStabProcessType;

@interface DGCBEVideoStabTask:NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;
@property (nonatomic, assign) bool validInput;

- (int)initTask;
- (CVPixelBufferRef)estimateCVPixelBuffer:(CVPixelBufferRef)buffer atIndex:(int)index;
- (CVPixelBufferRef)warpCVPixelBuffer:(CVPixelBufferRef)buffer atIndex:(int)index;
- (int)destroyTask;

@end

#endif /* BEVideoStabTask_h */
