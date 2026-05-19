//  DGCBEAvaBoostAlgorithmTask.m
//  BECore

#import "DGCBEAvaBoostAlgorithmTask.h"

@implementation DGCBEAvaBoostAlgorithmResult

@end

@interface DGCBEAvaBoostAlgorithmTask() {
    bef_effect_handle_t     _dgc_handle;
    bef_ai_avaboost_ret     _dgc_ret;
}

@property (nonatomic, strong) id<BEAvaBoostResourceProvider> provider;

@end

@implementation DGCBEAvaBoostAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)AVABOOST {
    GET_TASK_KEY(avaboost, YES)
}

- (int)initTask {
#if BEF_AVABOOST_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_avaboost_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_avaboost_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_avaboost_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_AVABOOST]);
        CHECK_RET_AND_RETURN(bef_effect_ai_avaboost_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE) {
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_avaboost_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_AVABOOST]);
        CHECK_RET_AND_RETURN(bef_effect_ai_avaboost_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_avaboost_init(_dgc_handle, self.provider.avaboostModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_avaboost_init, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAvaBoostAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_AVABOOST_TOB
    DGCBEAvaBoostAlgorithmResult* dgc_result = [DGCBEAvaBoostAlgorithmResult new];
    
    RECORD_TIME(detectAvaBoost)
    bef_effect_result_t dgc_ret = bef_effect_ai_avaboost_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &_dgc_ret);
    STOP_TIME(detectAvaBoost)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_avaboost_detect, dgc_ret, dgc_result)
    dgc_result.avaboost_ret = &_dgc_ret;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_AVABOOST_TOB
    bef_effect_ai_avaboost_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEAvaBoostAlgorithmTask.AVABOOST;
}

@end
