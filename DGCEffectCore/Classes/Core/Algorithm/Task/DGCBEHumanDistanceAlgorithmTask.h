//  DGCBEHumanDistanceAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "bef_effect_ai_face_detect.h"
#import "bef_effect_ai_human_distance.h"

@protocol BEHumanDistanceResourceProvider <BEFaceResourceProvider>

@end

@interface DGCBEHumanDistanceAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_face_info *faceInfo;
@property (nonatomic, assign) bef_ai_human_distance_result *distanceInfo;

@end

@interface DGCBEHumanDistanceAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)HUMAN_DISTANCE;

- (void)setFOV:(float)fov;

@end
