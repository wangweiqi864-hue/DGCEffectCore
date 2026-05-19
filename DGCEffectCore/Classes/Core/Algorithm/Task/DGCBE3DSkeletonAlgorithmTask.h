//  DGCBE3DSkeletonAlgorithmTask.h
//  Core


#ifndef BE3DSkeletonAlgorithmTask_h
#define BE3DSkeletonAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_3d_skeleton.h"

@protocol BE3DSkeletonResourceProvider <BEAlgorithmResourceProvider>

- (const char *)skeletonModel;
- (const char *)skeleton3DModel;

@end

@interface DGCBE3DSkeletonAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_skeleton3d_ret *skeletonInfo;

@end

@interface DGCBE3DSkeletonAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)SKELETON3D;

@end

#endif /* BE3DSkeletonAlgorithmTask_h */
