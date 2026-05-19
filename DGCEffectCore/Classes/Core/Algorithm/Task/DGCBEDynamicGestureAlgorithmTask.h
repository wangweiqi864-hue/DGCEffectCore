//  DGCBEDynamicGestureAlgorithmTask.h
//  BECore


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_dynamic_gesture.h"

@protocol BEDynamicGestureResourceProvider <BEAlgorithmResourceProvider>
- (const char *)dynamicGestureModelPath;
@end

@interface DGCBEDynamicGestureAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_dynamic_gesture_info *gestureInfo;
@property (nonatomic, assign) int gestureNum;

@end

@interface DGCBEDynamicGestureAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)DYNAMIC_GESTURE;

@end
