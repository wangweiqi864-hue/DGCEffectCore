//  DGCBESkySegAlgorithmTask.m
// EffectsARSDK


#import "DGCBESkySegAlgorithmTask.h"
#import "bef_effect_ai_skyseg.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int WIDTH = 128;
static int HEIGHT = 224;

@implementation DGCBESkySegAlgorithmResult

@end
@interface DGCBESkySegAlgorithmTask () {
    bef_ai_skyseg_handle            _dgc_handle;
    unsigned char                   *_dgc_skySegInfo;
    int                             _dgc_size[3];
    int                             _dgc_skySegInfoLen;
}

@property (nonatomic, strong) id<BESkyResourceProvider> provider;

@end

@implementation DGCBESkySegAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)SKY_SEG {
    GET_TASK_KEY(skySeg, YES)
}

- (int)initTask {
#if BEF_SKY_SEG_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_skyseg_create_handle(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_skyseg_create_handle, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_skyseg_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKY_SEG]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skyseg_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_skyseg_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKY_SEG]);
        CHECK_RET_AND_RETURN(bef_effect_ai_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_skyseg_init_model(_dgc_handle, self.provider.skySegModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_skyseg_init_model, dgc_ret)
    dgc_ret = bef_effect_ai_skyseg_set_param(_dgc_handle, WIDTH, HEIGHT);
    CHECK_RET_AND_RETURN(bef_effect_ai_skyseg_set_param, dgc_ret)
    return dgc_ret;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_SKY_SEG_TOB
    DGCBESkySegAlgorithmResult *dgc_result = [DGCBESkySegAlgorithmResult new];
    bef_effect_result_t dgc_ret = bef_effect_ai_skyseg_get_output_shape(_dgc_handle, _dgc_size, _dgc_size + 1, _dgc_size + 2);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_skyseg_get_output_shape, dgc_ret, dgc_result)
    if (_dgc_skySegInfoLen != _dgc_size[0] * _dgc_size[1] * _dgc_size[2]) {
        if (_dgc_skySegInfo != nil) {
            free(_dgc_skySegInfo);
        }
        _dgc_skySegInfoLen = _dgc_size[0] * _dgc_size[1] * _dgc_size[2];
        _dgc_skySegInfo = malloc(_dgc_skySegInfoLen);
    }
    
    bool dgc_hasSky;
    RECORD_TIME(skySeg)
    dgc_ret = bef_effect_ai_skyseg_detect(_dgc_handle, buffer, format, width, height, stride, rotation, _dgc_skySegInfo, false, true, &dgc_hasSky);
    STOP_TIME(skySeg)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_skyseg_detect, dgc_ret, dgc_result)
    dgc_result.mask = _dgc_skySegInfo;
    dgc_result.size = _dgc_size;
    dgc_result.hasSky = dgc_hasSky;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_SKY_SEG_TOB
    bef_effect_ai_skyseg_destroy(_dgc_handle);
    free(_dgc_skySegInfo);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBESkySegAlgorithmTask.SKY_SEG;
}

@end
