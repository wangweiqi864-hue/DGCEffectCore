//  DGCBEDynamicGestureAlgorithmTask.h
//  BECore


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_skin_segmentation.h"

@protocol BESkinSegmentationResourceProvider <BEAlgorithmResourceProvider>
- (const char *)skinSegmentationModelPath;
@end

@interface DGCBESkinSegmentationAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_skin_segmentation_ret *skinSegInfo;

@end

@interface DGCBESkinSegmentationAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)SKIN_SEGMENTATION;

@end
