//  DGCBEC1AlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_c1.h"

@protocol BEC1ResourceProvider <BEAlgorithmResourceProvider>
- (const char *)c1ModelPath;
@end

@interface DGCBEC1AlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_c1_output *c1Info;

@end

@interface DGCBEC1AlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)C1;

@end
