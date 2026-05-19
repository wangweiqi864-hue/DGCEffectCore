//  DGCBEDynamicGestureAlgorithmResult.m
//  BECore


#import "DGCBEDynamicGestureAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int MAX_NUM = 1;

@implementation DGCBEDynamicGestureAlgorithmResult

@end
@interface DGCBEDynamicGestureAlgorithmTask () {
    bef_effect_handle_t           _dgc_handle;
    bef_ai_dynamic_gesture_info   *_dgc_gestureInfo;
}

@property (nonatomic, strong) id<BEDynamicGestureResourceProvider> provider;

@end

@implementation DGCBEDynamicGestureAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)DYNAMIC_GESTURE {
    GET_TASK_KEY(dynamicGesture, YES)
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (int)initTask {
#if BEF_DYNAMIC_GESTURE_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_dynamic_gesture_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_dynamic_gesture_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_dynamic_gesture_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_DYNAMIC_GESTURE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_dynamic_gesture_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_dynamic_gesture_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_DYNAMIC_GESTURE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_dynamic_gesture_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_dynamic_gesture_init(_dgc_handle, self.provider.dynamicGestureModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_dynamic_gesture_init, dgc_ret)
    
    dgc_ret = bef_effect_ai_dynamic_gesture_set_paramS(_dgc_handle, BEF_AI_DYNAMIC_GESTURE_MODEL_GESTURE_CLS, "algo_gu8lpqg5tc_v1.2.model");
    CHECK_RET_AND_RETURN(bef_effect_ai_dynamic_gesture_set_paramS, dgc_ret);
    
    _dgc_gestureInfo = malloc(BEF_MAX_GESTURE_HAND_NUM * sizeof(bef_ai_dynamic_gesture_info));
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEDynamicGestureAlgorithmResult *)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_DYNAMIC_GESTURE_TOB
    int dgc_gestureNum = BEF_MAX_GESTURE_HAND_NUM;
    DGCBEDynamicGestureAlgorithmResult *dgc_result = [DGCBEDynamicGestureAlgorithmResult new];
    RECORD_TIME(dynamicGesture)
    bef_effect_result_t dgc_ret = bef_effect_ai_dynamic_gesture_detect(_dgc_handle, buffer, format, width, height, stride, rotation, &dgc_gestureNum, &_dgc_gestureInfo);
    STOP_TIME(dynamicGesture)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_hand_detect, dgc_ret, dgc_result)
    dgc_result.gestureInfo = _dgc_gestureInfo;
    dgc_result.gestureNum = dgc_gestureNum;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_DYNAMIC_GESTURE_TOB
    free(_dgc_gestureInfo);
    return bef_effect_ai_dynamic_gesture_release(_dgc_handle);
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEDynamicGestureAlgorithmTask.DYNAMIC_GESTURE;
}

@end
