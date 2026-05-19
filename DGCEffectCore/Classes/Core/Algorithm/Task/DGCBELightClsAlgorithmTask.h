//  DGCBELightClsAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_lightcls.h"

@protocol BELightClsResourceProvider <BEAlgorithmResourceProvider>

- (const char *)lightClsModelPath;

@end

@interface DGCBELightClsAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_light_cls_result *ligthInfo;

@end

@interface DGCBELightClsAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)LIGHT_CLS;

@end
