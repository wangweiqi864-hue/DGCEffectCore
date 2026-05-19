//  DGCBEC1AlgorithmTask.m
// EffectsARSDK


#import "DGCBEC1AlgorithmTask.h"
#import "bef_effect_ai_c1.h"

@implementation DGCBEC1AlgorithmResult

@end
@interface DGCBEC1AlgorithmTask () {
    bef_ai_c1_handle         _dgc_handle;
    bef_ai_c1_output            _dgc_c1Info;
}

@property (nonatomic, strong) id<BEC1ResourceProvider> provider;

@end

@implementation DGCBEC1AlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)C1 {
    GET_TASK_KEY(c1, YES)
}

- (int)initTask {
#if BEF_C1_TOB

    bef_effect_result_t dgc_ret = bef_effect_ai_c1_create(&_dgc_handle, BEF_AI_C1_MODEL_SMALL, self.provider.c1ModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_c1_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_c1_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_C1]);
        CHECK_RET_AND_RETURN(bef_effect_ai_c1_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;

        dgc_ret = bef_effect_ai_c1_check_onine_license(_dgc_handle, [self.licenseProvider licensePath:BEF_C1]);
        CHECK_RET_AND_RETURN(bef_effect_ai_c1_check_onine_license, dgc_ret)
    }

    dgc_ret = bef_effect_ai_c1_set_param(_dgc_handle, BEF_AI_C1_USE_MultiLabels, 1);
    CHECK_RET_AND_RETURN(bef_effect_ai_c1_set_param, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEC1AlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_C1_TOB
    DGCBEC1AlgorithmResult *dgc_result = [DGCBEC1AlgorithmResult new];
    RECORD_TIME(c1)
    bef_effect_result_t dgc_ret = bef_effect_ai_c1_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &_dgc_c1Info);
    STOP_TIME(c1)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_c1_detect, dgc_ret, dgc_result)
    dgc_result.c1Info = &_dgc_c1Info;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_C1_TOB
    bef_effect_ai_c1_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEC1AlgorithmTask.C1;
}

@end
