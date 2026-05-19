//
//  BEVideoDeflicker.m
//  BECore
//
//  Created by ByteDance on 2023/05/26.
//

#import "DGCBETimeRecoder.h"
#import "DGCBEVideoDeflickerTask.h"
#import "DGCBELensResourceHelper.h"
#import "bef_ai_image_quality_enhancement_video_deflicker.h"

#import "bef_effect_ai_log.h"
#import "bef_effect_ai_error_code_format.h"

@interface DGCBEVideoDeflickerTask (){
    BOOL _dgc_isFirstFrame;
}
    
@property(nonatomic, assign)bef_image_quality_enhancement_handle handle;

@end

@implementation DGCBEVideoDeflickerTask

-(instancetype) init{
    self = [super init];
    if(self){
        _handle = 0;
    }
    return self;
}

- (int)initTask{
#if BEF_LENS_VIDEO_DEFLICKER_TOB
    bef_ai_video_deflicker_init_config dgc_config;
    memset(&dgc_config, 0, sizeof(dgc_config));
    
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    
    dgc_config.kernelBinPath = [[DGCBELensResourceHelper new] videoDeflickerLibPath];
    dgc_config.dataType = BEF_AI_LENS_PXIELBUFFER_BGRA;
    dgc_config.algType = BEF_VIDEO_DEFLICKER_ALG_DELAY;
    
    int dgc_ret = bef_ai_image_quality_enhancement_video_deflicker_create(&_handle, &dgc_config);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_deflicker_create, dgc_ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_image_quality_enhancement_video_deflicker_check_license(_handle, [self.provider licensePath:BEF_VIDEO_DEFLICKER]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_deflicker_check_license, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE) {
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        dgc_ret = bef_ai_image_quality_enhancement_video_deflicker_check_online_license(_handle, [self.provider licensePath:BEF_VIDEO_DEFLICKER]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_deflicker_check_online_license, dgc_ret)
    }
    _dgc_isFirstFrame = YES;
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)dgc_buffer{
#if BEF_LENS_VIDEO_DEFLICKER_TOB
    if(dgc_buffer == NULL){
        LOGCV_E("video deflicker invalid input dgc_buffer");
        return NULL;
    }
    
    bef_ai_video_deflicker_process_config dgc_config;
    dgc_config.width = (int)CVPixelBufferGetWidth(dgc_buffer);
    dgc_config.height = (int)CVPixelBufferGetHeight(dgc_buffer);
    dgc_config.strideWidth = (int)CVPixelBufferGetBytesPerRow(dgc_buffer);
    dgc_config.strideHeight = dgc_config.height;
    dgc_config.open = 1;
    if(_dgc_isFirstFrame){
        dgc_config.isFirst = 1;
        _dgc_isFirstFrame = NO;
    }else{
        dgc_config.isFirst = 0;
    }
    dgc_config.blendRate = 0.8;
    dgc_config.kernelSize = 41;
    dgc_config.data.buffer = dgc_buffer;
    
    // uesless param;
    dgc_config.inputTextureId = -1;
    dgc_config.stMatrix = NULL;
    
    CVPixelBufferRef dgc_processedBuffer = nil;
    bef_ai_lens_video_deflicker_data dgc_output;
    memset(&dgc_output, 0, sizeof(dgc_output));
    RECORD_TIME(video_deflicker);
    int dgc_ret = bef_ai_image_quality_enhancement_video_deflicker_process(_handle, &dgc_config, &dgc_output);
    STOP_TIME(video_deflicker);
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_video_deflicker_process, dgc_ret, NULL);
    
    dgc_processedBuffer = (CVPixelBufferRef)dgc_output.buffer;
    NSAssert(dgc_processedBuffer, @"null result");
    
    return dgc_processedBuffer;
#endif
    return NULL;
}

- (int)destroyTask{
#if BEF_LENS_VIDEO_DEFLICKER_TOB
    if(_handle){
        int dgc_ret = bef_ai_image_quality_enhancement_video_deflicker_destroy(_handle);
        CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_video_deflicker_destroy, dgc_ret, BEF_RESULT_FAIL);
    }
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end


