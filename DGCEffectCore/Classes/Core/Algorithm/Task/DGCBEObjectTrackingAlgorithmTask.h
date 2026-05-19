//
//  DGCBEObjectTrackingAlgorithmTask.h
//  Core
//

#ifndef BEObjectTrackingAlgorithmTask_h
#define BEObjectTrackingAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_object_tracking.h"

@protocol BEObjectTrackingResourceProvider <BEAlgorithmResourceProvider>

- (const char *)objectTrackingModel;

@end

@interface DGCBEObjectTrackingAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_object_tracking_bbox* bbox;
@property (nonatomic, assign) bool isTracking;
@property (nonatomic, assign) bool bboxInited;

@end

@interface DGCBEObjectTrackingAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)OBJECT_TRACKING;
+ (DGCBEAlgorithmKey *)OBJECT_TRACKING_START;
+ (DGCBEAlgorithmKey *)OBJECT_TRACKING_TOUCH_EVENT;

- (void)processTouchEvent:(bef_ai_touch_event_code)eventCode x:(float)x y:(float)y;

@end

#endif /* BEObjectTrackingAlgorithmTask_h */
