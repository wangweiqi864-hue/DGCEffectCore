//  BECarDamageDetectTask.m
// EffectsARSDK


#import "DGCBECarDetectTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "bef_effect_ai_car_detect.h"

@implementation DGCBECarAlgorithmResult

@end
@interface DGCBECarDetectTask () {
    bef_ai_car_handle         _dgc_handle;
    bef_ai_car_ret              _dgc_carInfo;
}

@property (nonatomic, strong) id<BECarResourceProvider> provider;

@end

@implementation DGCBECarDetectTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)CAR {
    GET_TASK_KEY(car, YES)
}

+ (DGCBEAlgorithmKey *)CAR_DETECT {
    GET_TASK_KEY(carDetect, NO)
}

+ (DGCBEAlgorithmKey *)CAR_BRAND_DETECT {
    GET_TASK_KEY(carBrand, NO)
}

- (int)initTask {
#if BEF_CAR_DETECT_TOB
    int ret = bef_effect_ai_car_detect_create_handle(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_create_handle, ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        ret = bef_effect_ai_car_detect_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_CAR_DETECT]);
        CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_check_license, ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        ret = bef_effect_ai_car_detect_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_CAR_DETECT]);
        CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_check_online_license, ret);
    }
    
    ret = bef_effect_ai_car_detect_init_model(_dgc_handle, BEF_AI_CarDetectModel, self.provider.carDetectModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_init_model, ret)
    ret = bef_effect_ai_car_detect_init_model(_dgc_handle, BEF_AI_BrandDetectModel, self.provider.carLandmarkModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_init_model, ret)
    ret = bef_effect_ai_car_detect_init_model(_dgc_handle, BEF_AI_BrandOcrModel, self.provider.carPlateOcrModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_init_model, ret)
    ret = bef_effect_ai_car_detect_init_model(_dgc_handle, BEF_AI_CarTrackModel, self.provider.carTrackModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_car_detect_init_model, ret)
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBECarAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_CAR_DETECT_TOB
    DGCBECarAlgorithmResult *dgc_result = [DGCBECarAlgorithmResult new];
    memset(&_dgc_carInfo, 0, sizeof(bef_ai_car_ret));
    RECORD_TIME(carDetect)
    int ret = bef_effect_ai_car_detect_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &_dgc_carInfo);
    STOP_TIME(carDetect)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_car_detect_detect, ret, dgc_result)
    
    dgc_result.carInfo = &_dgc_carInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_CAR_DETECT_TOB
    bef_effect_ai_car_detect_destroy(_dgc_handle);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBECarDetectTask.CAR;
}

- (void)setConfig:(DGCBEAlgorithmKey *)key p:(NSObject *)p {
#if BEF_CAR_DETECT_TOB
    [super setConfig:key p:p];
    
    int ret = bef_effect_ai_car_detect_set_paramf(_dgc_handle, BEF_AI_BrandRec, [self boolConfig:DGCBECarDetectTask.CAR_BRAND_DETECT orDefault:NO] ? 1.f : -1.f);
    ret = bef_effect_ai_car_detect_set_paramf(_dgc_handle, BEF_AI_CarDetct, [self boolConfig:DGCBECarDetectTask.CAR_DETECT orDefault:NO] ? 1.f : -1.f);
#endif
}

@end
