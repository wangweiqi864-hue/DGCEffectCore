//  DGCBESkeletonAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_skeleton.h"

@protocol BESkeletonResourceProvider <BEAlgorithmResourceProvider>

- (const char *)skeletonModel;

@end

@interface DGCBESkeletonAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_skeleton_info *skeletonInfo;
@property (nonatomic, assign) int count;

@end

@interface DGCBESkeletonAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)SKELETON;

@end
