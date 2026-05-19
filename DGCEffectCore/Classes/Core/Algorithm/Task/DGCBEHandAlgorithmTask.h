//  DGCBEHandAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import <bef_effect_ai_hand.h>

@protocol BEHandResourceProvider <BEAlgorithmResourceProvider>

- (const char *)handModel;
- (const char *)handBoxModel;
- (const char *)handGestureModel;
- (const char *)handKeyPointModel;

@end

@interface DGCBEHandAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_hand_info *handInfo;

@end


@interface DGCBEHandAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)HAND;

@end
