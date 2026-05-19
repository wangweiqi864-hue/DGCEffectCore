//  DGCBEHeadSegmentAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "bef_effect_ai_headseg.h"

@protocol BEHeadSegmentResourceProvider <BEFaceResourceProvider>
- (const char *)headSegmentModelPath;
@end

@interface DGCBEHeadSegmentAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_headseg_output *headSegInfo;

@end

@interface DGCBEHeadSegmentAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)HEAD_SEGMENT;

@end
