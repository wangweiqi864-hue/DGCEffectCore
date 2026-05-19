//  DGCBEC2AlgorithmTask.m
// EffectsARSDK


#import "DGCBEC2AlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "bef_effect_ai_c2.h"

@implementation DGCBEC2AlgorithmResult

@end
@interface DGCBEC2AlgorithmTask () {
    bef_ai_c2_handle         _dgc_handle;
    bef_ai_c2_ret            _dgc_c2Info;
}

@property (nonatomic, strong) id<BEC2ResourceProvider> provider;

@end

@implementation DGCBEC2AlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)C2 {
    GET_TASK_KEY(c2, YES)
}

- (int)initTask {
#if BEF_C2_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_c2_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_c2_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_c2_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_C2]);
        CHECK_RET_AND_RETURN(bef_effect_ai_c2_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_c2_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_C2]);
        CHECK_RET_AND_RETURN(bef_effect_ai_c2_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_c2_set_model(_dgc_handle, BEF_AI_kC2Model1, self.provider.c2Model);
    CHECK_RET_AND_RETURN(bef_effect_ai_c2_set_model, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEC2AlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_C2_TOB
    
    DGCBEC2AlgorithmResult *dgc_result = [DGCBEC2AlgorithmResult new];
    memset(&_dgc_c2Info, 0, sizeof(bef_ai_c2_ret));
    RECORD_TIME(c2)
    bef_effect_result_t dgc_ret = bef_effect_ai_c2_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &_dgc_c2Info);
    STOP_TIME(c2)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_c2_detect, dgc_ret, dgc_result)
    
    dgc_result.c2Info = _dgc_c2Info;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_C2_TOB
    bef_effect_ai_c2_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}


- (DGCBEAlgorithmKey *)key {
    return DGCBEC2AlgorithmTask.C2;
}

@end
