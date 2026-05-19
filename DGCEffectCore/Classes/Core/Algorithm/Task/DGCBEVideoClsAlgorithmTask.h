//  DGCBEVideoClsAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_video_cls.h"

@protocol BEVideoClsResourceProvider <BEAlgorithmResourceProvider>

- (const char *)videoClsModelPath;

@end

@interface DGCBEVideoClsAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_video_cls_ret *videoInfo;

@end

@interface DGCBEVideoClsAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)VIDEO_CLS;

@end
