//  DGCBEDynamicGestureAlgorithmTask.h
//  BECore


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_bach_skeleton.h"

@protocol BEBachSkeletonResourceProvider <BEAlgorithmResourceProvider>

- (const char *)bachSkeletonModel;

@end

@interface DGCBEBachSkeletonAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_bach_skeleton_info *skeletonInfo;
@property (nonatomic, assign) int count;

@end

@interface DGCBEBachSkeletonAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)BACH_SKELETON;

@end
