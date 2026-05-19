//  DGCBESkySegAlgorithmTask.h
// EffectsARSDK


#ifndef BESkySegAlgorithmTask_h
#define BESkySegAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"

@protocol BESkyResourceProvider <BEAlgorithmResourceProvider>

- (const char *)skySegModelPath;

@end

@interface DGCBESkySegAlgorithmResult : NSObject

@property (nonatomic, assign) unsigned char *mask;
@property (nonatomic, assign) int *size;
@property (nonatomic, assign) BOOL hasSky;

@end

@interface DGCBESkySegAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)SKY_SEG;

@end

#endif /* BESkySegAlgorithmTask_h */
