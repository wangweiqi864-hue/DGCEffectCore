//  DGCBEPortraitMattingAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"

@protocol BEPortraitMattingResourceProvider <BEAlgorithmResourceProvider>
- (const char *)portraitMattingModelPath;
@end

@interface DGCBEPortraitMattingAlgorithmResult : NSObject

@property (nonatomic, assign) unsigned char *mask;
@property (nonatomic, assign) int *size;

@end

@interface DGCBEPortraitMattingAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)PORTRAIT_MATTING;

@end
