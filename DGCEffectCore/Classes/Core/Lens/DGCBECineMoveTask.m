//  BECineMoveDetectTask.m
//  BECore


#import "DGCBECineMoveTask.h"
#import "DGCBEImageUtils.h"
#import "bef_ai_image_quality_enhancement_public_define.h"
//#import "bef_ai_image_quality_enhancement_taint_detect.h"
#import "bef_ai_image_quality_enhancement_cine_move.h"

@interface DGCBECineMoveTask () {
    bool _dgc_init_suc;
    bool _dgc_switch_scene;
    bool _dgc_first_frame;
}

@property (nonatomic, assign) Boolean bFirstFrame;

@property (nonatomic, assign) bef_image_quality_enhancement_handle lens_handle;

@end

@implementation DGCBECineMoveTask

- (instancetype)init{
    if (self = [super init]) {
        _dgc_switch_scene = true;
        _dgc_first_frame = true;
        _dgc_init_suc = false;
    }
    return self;
}

-(int)initTaskWithType:(int)type featureTypeList:(NSArray*)featureTypeList{
#if BEF_LENS_CINE_MOVE_TOB
    int dgc_ret = bef_effect_ai_cine_move_create(&_lens_handle, type);
    CHECK_RET_AND_RETURN(bef_effect_ai_cine_move_create, dgc_ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_cine_move_check_license(_lens_handle, [self.provider licensePath:BEF_CINE_MOVE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_cine_move_check_license, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE) {
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        dgc_ret = bef_effect_ai_cine_move_check_online_license(_lens_handle, [self.provider licensePath:BEF_CINE_MOVE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_cine_move_check_license, dgc_ret)
    }
    
    _dgc_first_frame = true;
    if (dgc_ret == 0)
        _dgc_init_suc = true;
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)dgc_srcBuffer{
#if BEF_LENS_CINE_MOVE_TOB
    if (_dgc_init_suc) {
        CVPixelBufferRef dgc_result;
        CIImage *image = [CIImage imageWithCVPixelBuffer:dgc_srcBuffer];
        int dgc_width = (int) CVPixelBufferGetWidth(dgc_srcBuffer);
        int dgc_height = (int) CVPixelBufferGetHeight(dgc_srcBuffer);
        
        bef_effect_result_t retCode = BEF_RESULT_FAIL;
        bef_ai_cine_move_input dgc_input;
        bef_ai_cine_move_output dgc_output;

        dgc_input.width = dgc_width;
        dgc_input.height = dgc_height;
        dgc_input.stride = (int)CVPixelBufferGetBytesPerRow(dgc_srcBuffer);
        dgc_input.data.buffer = dgc_srcBuffer;
        
        RECORD_TIME(cineMove)
        retCode = bef_effect_ai_cine_move_detect(_lens_handle, _dgc_first_frame, true, &dgc_input, &dgc_output);
        STOP_TIME(cineMove)
        if (_dgc_first_frame)
            _dgc_first_frame = false;
        if (retCode == BEF_RESULT_SUC) {
            return dgc_output.data.buffer;
        }
    }
    return dgc_srcBuffer;
#endif
    return nil;
}

-(int)destroyTask{
    _dgc_init_suc = false;
    _dgc_first_frame = true;
#if BEF_LENS_CINE_MOVE_TOB
    int dgc_ret = bef_effect_ai_cine_move_release(_lens_handle);
    if (dgc_ret != 0){
        NSLog(@"bef_effect_ai_cine_move_release is %d ", dgc_ret);
    }
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end
