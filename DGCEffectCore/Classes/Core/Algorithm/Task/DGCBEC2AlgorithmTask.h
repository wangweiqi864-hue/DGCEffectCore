//  DGCBEC2AlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_c2.h"

@protocol BEC2ResourceProvider <BEAlgorithmResourceProvider>
- (const char *)c2Model;
@end

@interface DGCBEC2AlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_c2_ret c2Info;

@end

@interface DGCBEC2AlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)C2;

@end
