//  DGCBEHandAlgorithmTask.m
// EffectsARSDK


#import "DGCBEHandAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int MAX_NUM = 1;
static BOOL NARUTO_GESTURE = true;
static float ENLARGE_FACTOR = 2.f;
static unsigned long long DETECT_CONFIG = BEF_AI_HAND_MODEL_DETECT | BEF_AI_HAND_MODEL_BOX_REG |
BEF_AI_HAND_MODEL_GESTURE_CLS| BEF_AI_HAND_MODEL_KEY_POINT;

@implementation DGCBEHandAlgorithmResult

@end
@interface DGCBEHandAlgorithmTask () {
    bef_ai_hand_sdk_handle          _dgc_handle;
    bef_ai_hand_info                _dgc_handInfo;
    unsigned long long              _dgc_detectConfig;
}

@property (nonatomic, strong) id<BEHandResourceProvider> provider;

@end

@implementation DGCBEHandAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)HAND {
    GET_TASK_KEY(hand, YES)
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _dgc_detectConfig = DETECT_CONFIG;
    }
    return self;
}

- (int)initTask {
#if BEF_HAND_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_hand_detect_create(&_dgc_handle, 0);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_hand_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HAND_DETECT]);
        CHECK_RET_AND_RETURN(bef_effect_ai_hand_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;

        dgc_ret = bef_effect_ai_hand_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HAND_DETECT]);
        CHECK_RET_AND_RETURN(bef_effect_ai_hand_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_hand_detect_setmodel(_dgc_handle, BEF_AI_HAND_MODEL_DETECT, self.provider.handModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_setmodel, dgc_ret)
    dgc_ret = bef_effect_ai_hand_detect_setmodel(_dgc_handle, BEF_AI_HAND_MODEL_BOX_REG, self.provider.handBoxModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_setmodel, dgc_ret)
    dgc_ret = bef_effect_ai_hand_detect_setmodel(_dgc_handle, BEF_AI_HAND_MODEL_GESTURE_CLS, self.provider.handGestureModel);
    CHECK_RET_AND_DO(bef_effect_ai_hand_detect_setmodel, dgc_ret, {
        _dgc_detectConfig &= ~ BEF_AI_HAND_MODEL_GESTURE_CLS;
    })
    dgc_ret = bef_effect_ai_hand_detect_setmodel(_dgc_handle, BEF_AI_HAND_MODEL_KEY_POINT, self.provider.handKeyPointModel);
    CHECK_RET_AND_DO(bef_effect_ai_hand_detect_setmodel, dgc_ret, {
        _dgc_detectConfig &= ~ BEF_AI_HAND_MODEL_KEY_POINT;
    })
    dgc_ret = bef_effect_ai_hand_detect_setparam(_dgc_handle, BEF_HAND_MAX_HAND_NUM, MAX_NUM);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_setparam, dgc_ret)
    dgc_ret = bef_effect_ai_hand_detect_setparam(_dgc_handle, BEF_HAND_NARUTO_GESTURE, NARUTO_GESTURE);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_setparam, dgc_ret)
    dgc_ret = bef_effect_ai_hand_detect_setparam(_dgc_handle, BEF_HNAD_ENLARGE_FACTOR_REG, ENLARGE_FACTOR);
    CHECK_RET_AND_RETURN(bef_effect_ai_hand_detect_setparam, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEHandAlgorithmResult *)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_HAND_TOB
    DGCBEHandAlgorithmResult *dgc_result = [DGCBEHandAlgorithmResult new];
    RECORD_TIME(detectHand)
    bef_effect_result_t dgc_ret = bef_effect_ai_hand_detect(_dgc_handle, buffer, format, width, height, stride, rotation, _dgc_detectConfig, &_dgc_handInfo, 0);
    STOP_TIME(detectHand)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_hand_detect, dgc_ret, dgc_result)
    dgc_result.handInfo = &_dgc_handInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_HAND_TOB

    bef_effect_ai_hand_detect_destroy(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEHandAlgorithmTask.HAND;
}

@end
