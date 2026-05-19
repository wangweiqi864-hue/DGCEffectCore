//  DGCBEGazeEstimationTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "bef_effect_ai_gaze_estimation.h"

@protocol BEGazeEstimationResourceProvider <BEAlgorithmResourceProvider, BEFaceResourceProvider>

- (const char *)gazeModel;

@end

@interface DGCBEGazeEstimationAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_gaze_estimation_info *gazeInfo;

@end

@interface DGCBEGazeEstimationTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)GAZE_ESTIMATION;

@end
