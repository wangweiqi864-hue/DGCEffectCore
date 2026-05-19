//  DGCBECineMoveTask.h
//  Core


#ifndef BECineMoveTask_h
#define BECineMoveTask_h

#import "DGCBEAlgorithmTask.h"
#import <CoreVideo/CoreVideo.h>

@interface DGCBECineMoveTask : NSObject

@property (nonatomic, strong) id<BELicenseProvider> provider;

-(int)initTaskWithType:(int)type featureTypeList:(NSArray*)featureTypeList;
- (CVPixelBufferRef) processCVPixelBuffer:(CVPixelBufferRef)srcBuffer;
- (int) destroyTask;

@end

#endif /* BECineMoveTask_h */
