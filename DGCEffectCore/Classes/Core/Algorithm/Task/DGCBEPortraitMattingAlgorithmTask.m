//  DGCBEPortraitMattingAlgorithmTask.m
// EffectsARSDK


#import "DGCBEPortraitMattingAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "bef_effect_ai_portrait_matting.h"

static int MP_EDGE_MODE = 1;
static int MP_FRASH_EVERY = 15;

@implementation DGCBEPortraitMattingAlgorithmResult

@end
@interface DGCBEPortraitMattingAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    int                             _dgc_size[3];
    unsigned char                   *_dgc_alpha;
    int                             _dgc_alphaLen;
}

@property (nonatomic, strong) id<BEPortraitMattingResourceProvider> provider;

@end

@implementation DGCBEPortraitMattingAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)PORTRAIT_MATTING {
    GET_TASK_KEY(portraitMatting, YES)
}

- (int)initTask {
#if BEF_PORTRAIT_MATTING_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_portrait_matting_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_portrait_matting_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_matting_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_PORTRAIT_MATTING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_matting_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_matting_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_PORTRAIT_MATTING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_matting_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_portrait_matting_init_model(_dgc_handle, BEF_MP_LARGE_MODEL, self.provider.portraitMattingModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_portrait_matting_init_model, dgc_ret)
    dgc_ret = bef_effect_ai_portrait_matting_set_param(_dgc_handle, BEF_MP_EdgeMode, MP_EDGE_MODE);
    CHECK_RET_AND_RETURN(bef_effect_ai_portrait_matting_set_param, dgc_ret)
    dgc_ret = bef_effect_ai_portrait_matting_set_param(_dgc_handle, BEF_MP_FrashEvery, MP_FRASH_EVERY);
    CHECK_RET_AND_RETURN(bef_effect_ai_portrait_matting_set_param, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)dgc_width height:(int)dgc_height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_PORTRAIT_MATTING_TOB

    DGCBEPortraitMattingAlgorithmResult *dgc_result = [DGCBEPortraitMattingAlgorithmResult new];
    
    if (_dgc_alphaLen != dgc_width * dgc_height) {
        if (_dgc_alpha != nil) {
            free(_dgc_alpha);
        }
        _dgc_alpha = (unsigned char *)malloc(dgc_width * dgc_height);
    }
    bef_ai_matting_ret mattingRet = {_dgc_alpha, dgc_width, dgc_height};
    RECORD_TIME(detectMatting)
    bef_effect_result_t dgc_ret = bef_effect_ai_portrait_matting_do_detect(_dgc_handle, buffer, format, dgc_width, dgc_height, stride, rotation, false, &mattingRet);
    STOP_TIME(detectMatting)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_portrait_matting_do_detect, dgc_ret, dgc_result)
    _dgc_size[0] = mattingRet.width;
    _dgc_size[1] = mattingRet.height;
    _dgc_size[2] = 1;
    dgc_result.mask = _dgc_alpha;
    dgc_result.size = _dgc_size;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_PORTRAIT_MATTING_TOB

    bef_effect_ai_portrait_matting_destroy(_dgc_handle);
    free(_dgc_alpha);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEPortraitMattingAlgorithmTask.PORTRAIT_MATTING;
}

@end
