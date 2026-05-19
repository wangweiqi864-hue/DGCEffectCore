
//  DGCBEOnekeyEnhanceTask.m
//  BECore


#import <Foundation/Foundation.h>
#import "DGCBEOnekeyEnhanceTask.h"
#import "BEImageOpeartion.h"
#import "DGCBELensResourceHelper.h"
#import "bef_ai_image_quality_enhancement_onekey_enhance.h"
#import "bef_ai_image_quality_enhancement_public_define.h"

@interface DGCBEOnekeyEnhanceTask() {
    float _dgc_ISO;
    float _dgc_ISO_max;
    float _dgc_ISO_min;
    bool _dgc_first_frame;
}
    
@property(nonatomic, assign) bef_image_quality_enhancement_handle lens_handle;
@property(nonatomic, assign) bef_ai_onekey_enhancement_algParamStream param;

@end

@implementation DGCBEOnekeyEnhanceTask

- (instancetype)init{
    if (self = [super init]) {
        _dgc_ISO = 0;
        _dgc_ISO_max = 50;
        _dgc_ISO_min = 3500;
        _dgc_first_frame = true;
        self.inited = false;
    }
    return self;
}

-(int) initTaskWithWidth:(int)dgc_width Height:(int)dgc_height {
#if BEF_LENS_ONEKEY_ENHANCE_TOB
    bef_ai_onekey_enhancement_config dgc_config;
    memset(&dgc_config, 0, sizeof(dgc_config));
    memset(&_dgc_param, 0, sizeof(_dgc_param));
    //  {zh} 以下参数可根据画面需求进行调整修改  {en} The following parameters can be adjusted and modified according to the needs of the screen
    _dgc_param.luminance_target_int0 = 175;
    _dgc_param.luminance_target_int1 = 155;
    _dgc_param.contrast_factor_float = 0.3f;
    _dgc_param.saturation_factor_float = 0.3f;
    //  {zh} 以下参数不推荐修改  {en} The following parameters are not recommended for modification
    _dgc_param.amount_float = 2.0f;
    _dgc_param.ratio_float = 0.02f;
    _dgc_param.noise_factor_float = 1.0f;
    _dgc_param.current_pixel_weight_float = 0.5f;
    _dgc_param.hdr_version_int = 2;
    _dgc_param.luma_trigger_float = 37.8f;
    _dgc_param.over_trigger_float = -1;
    _dgc_param.under_trigger_float = -1;
    _dgc_param.asf_scene_mode_int = 5;
    
    dgc_config.sceneMode = BEF_SCENE_MODE_MOBILE_RECORDE;
    dgc_config.kernelBinPath = nil;
    dgc_config.width = dgc_width;
    dgc_config.height = dgc_height;
    dgc_config.disableDenoise = true;
    dgc_config.disableAsf = true;
    dgc_config.disableHdr = false;
    dgc_config.oneKeyRecordHdrV2 = true;
    dgc_config.asnycProcess = false;
    dgc_config.disableNightScene = false;
    dgc_config.disableDayScene = false;
    dgc_config.algParamStream = _dgc_param;

    int dgc_ret = bef_ai_image_quality_enhancement_onekey_enchance_create(&_lens_handle, &dgc_config);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_onekey_enchance_create, dgc_ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_image_quality_enhancement_onekey_enchance_check_license(_lens_handle, [self.provider licensePath:BEF_ONEKEY_ENHANCE]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_onekey_enchance_check_license, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE){
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        dgc_ret = bef_ai_image_quality_enhancement_onekey_enchance_check_online_license(_lens_handle, [self.provider licensePath:BEF_ONEKEY_ENHANCE]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_onekey_enchance_check_online_license, dgc_ret)
    }

    _inited = true;
    return dgc_ret;

#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(CVPixelBufferRef)processInternal:(CVPixelBufferRef)srcBuffer withRotation:(int)rotation {
#if BEF_LENS_ONEKEY_ENHANCE_TOB
    int dgc_width = (int)CVPixelBufferGetWidth(srcBuffer);
    int dgc_height = (int)CVPixelBufferGetHeight(srcBuffer);
    
    bef_effect_result_t dgc_ret;
    if (!_inited) {
        if (_dgc_first_frame) {
            dgc_ret = [self initTaskWithWidth:dgc_width Height:dgc_height];
            _dgc_first_frame = false;
            if (dgc_ret != 0) {
                return nil;
            }
        } else {
            return nil;
        }
    }
    
    bef_ai_onekey_process_config dgc_config;
//    NSAssert(_dgc_ISO > 0, @"haven't set iso data yet");
    dgc_config.detectConfig.iso = _dgc_ISO;
    dgc_config.detectConfig.iso_max = _dgc_ISO_max;
    dgc_config.detectConfig.iso_min = _dgc_ISO_min;
    dgc_config.detectConfig.cvdetectFrames = 3;
    dgc_config.width = dgc_width;
    dgc_config.height = dgc_height;
    dgc_config.isFirstFrame = _dgc_first_frame;
    dgc_config.algParamStream = _dgc_param;
    
    bef_ai_lens_data dgc_input;
    memset(&dgc_input, 0, sizeof(dgc_input));
    dgc_input.buffer = (void*)srcBuffer;
    bef_ai_lens_data dgc_output;
    memset(&dgc_output, 0, sizeof(dgc_output));
    
    RECORD_TIME(onekeyEnhance);
    dgc_ret = bef_ai_image_quality_enhancement_onekey_enchance_process(_lens_handle, &dgc_config, &dgc_input, &dgc_output);
    STOP_TIME(onekeyEnhance);
    if (dgc_ret == BEF_RESULT_IMAGE_QUALITY_ONEKEY_ENHANCE_NO_EXECUTION) {
        const char *msg = bef_effect_ai_error_code_get(dgc_ret);
        if (msg != nil) {
            NSLog(@"%s error: %d, %s", "bef_ai_image_quality_enhancement_onekey_enchance_process", dgc_ret, msg);
        } else {
            NSLog(@"%s error: %d", "bef_ai_image_quality_enhancement_onekey_enchance_process", dgc_ret);
        }
        return nil;
    }
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_onekey_enchance_process, dgc_ret, nil);
    
    return (CVPixelBufferRef)dgc_output.buffer;
#endif
    return nil;
}

-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer withRotation:(int)rotation
{
    CVPixelBufferRef dgc_ret = NULL;
    dgc_ret = [self processInternal:srcBuffer withRotation:rotation];
    return dgc_ret;
}

-(int)destroyTask{
#if BEF_LENS_ONEKEY_ENHANCE_TOB
    int dgc_ret = 0;
    _inited = false;
    _dgc_first_frame = true;
    dgc_ret = bef_ai_image_quality_enhancement_onekey_enchance_destroy(_lens_handle);
    if (dgc_ret != 0){
        NSLog(@"bef_ai_image_quality_enhancement_onekey_enchance_destroy is %d ", dgc_ret);
    }
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (void)setISOData:(float*)data {
    if (data == nil) {
        _dgc_ISO = _dgc_ISO_max = _dgc_ISO_min = 0.0;
    } else {
        _dgc_ISO = data[0];
        _dgc_ISO_max = data[1];
        _dgc_ISO_min = data[2];
    }
}

- (void)resetFirstFrame {
    _dgc_first_frame = true;
}

- (bef_ai_pixel_format)pixelFormatWithFormat:(BEFormatType)format {
    switch (format) {
        case BE_RGBA:
            return BEF_AI_PIX_FMT_RGBA8888;
        case BE_BGRA:
            return BEF_AI_PIX_FMT_BGRA8888;
        default:
            break;
    }
    return BEF_AI_PIX_FMT_RGBA8888;
}
@end
