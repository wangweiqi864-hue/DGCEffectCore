//  DGCBELightClsAlgorithmTask.m
// EffectsARSDK


#import "DGCBELightClsAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int FPS = 5;
@implementation DGCBELightClsAlgorithmResult

@end
@interface DGCBELightClsAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_light_cls_result         _dgc_lightClsInfo;
}

@property (nonatomic, strong) id<BELightClsResourceProvider> provider;

@end

@implementation DGCBELightClsAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)LIGHT_CLS {
    GET_TASK_KEY(lightCls, YES)
}

- (int)initTask {
#if BEF_LIGHT_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_lightcls_create(&_dgc_handle, self.provider.lightClsModelPath, FPS);
    CHECK_RET_AND_RETURN(bef_effect_ai_lightcls_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_lightcls_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_LIGHT_CLS]);
        CHECK_RET_AND_RETURN(bef_effect_ai_lightcls_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;

        dgc_ret = bef_effect_ai_lightcls_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_LIGHT_CLS]);
        CHECK_RET_AND_RETURN(bef_effect_ai_lightcls_check_online_license, dgc_ret);
    }

    return dgc_ret;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_LIGHT_TOB

    DGCBELightClsAlgorithmResult *dgc_result = [DGCBELightClsAlgorithmResult new];
    RECORD_TIME(detectLight)
    bef_effect_result_t dgc_ret = bef_effect_ai_lightcls_detect(_dgc_handle, buffer, format, width, height, stride, rotation, &_dgc_lightClsInfo);
    STOP_TIME(detectLight)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_lightcls_detect, dgc_ret, dgc_result)
    dgc_result.ligthInfo = &_dgc_lightClsInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_LIGHT_TOB

    bef_effect_ai_lightcls_release(_dgc_handle);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBELightClsAlgorithmTask.LIGHT_CLS;
}

@end
