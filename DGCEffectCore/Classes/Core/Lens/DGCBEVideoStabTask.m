//
//  DGCBEVideoStabTask.m
//  BECore
//

#import "DGCBEVideoStabTask.h"
#import "DGCBETimeRecoder.h"
#import "DGCBEImageUtils.h"
#import "bef_ai_image_quality_enhancement_vas.h"

#import "bef_effect_ai_log.h"
#import "bef_effect_ai_error_code_format.h"

#define VASMAXWIDTH 2048
#define VASMAXHEIGHT 2048

@interface DGCBEVideoStabTask (){
    BOOL _dgc_isFirstFrame;
}
    
@property(nonatomic, assign)bef_image_quality_enhancement_handle handle;
@property(nonatomic, strong)DGCBEImageUtils* imgUtils;
@property(nonatomic, strong)DGCBEBuffer* resultBuffer;

@end

@implementation DGCBEVideoStabTask

-(instancetype) init{
    self = [super init];
    if(self){
        _handle = 0;
        _validInput = false;
        _imgUtils = [[DGCBEImageUtils alloc] init];
    }
    return self;
}

- (int)initTask{
#if BEF_LENS_VIDEO_STAB_TOB
    bef_ai_vas_config dgc_config;
    memset(&dgc_config, 0, sizeof(dgc_config));
    
    dgc_config.vasLevel.vasMaxCropRatio = 0.25;
    dgc_config.vasLevel.vasSmoothRadius = 60;
    dgc_config.vasLevel.vasMotionType = 1;
    dgc_config.vasMaxWidth = VASMAXWIDTH;
    dgc_config.vasMaxHeight = VASMAXHEIGHT;
    dgc_config.vasThreadNum = 4;
    
    int dgc_ret = bef_ai_image_quality_enhancement_vas_create(&_handle, &dgc_config);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vas_create, dgc_ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_image_quality_enhancement_vas_check_license(_handle, [self.provider licensePath:BEF_VIDEO_STAB]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vas_check_license, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE) {
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        const char* licensePath = [self.provider licensePath:BEF_VIDEO_STAB];
        dgc_ret = bef_ai_image_quality_enhancement_vas_check_online_license(_handle, licensePath);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vas_check_online_license, dgc_ret)
    }
    
    _dgc_isFirstFrame = YES;
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (CVPixelBufferRef)estimateCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer atIndex:(int)dgc_index{
#if BEF_LENS_VIDEO_STAB_TOB
    if(dgc_pixelBuffer == NULL){
        LOGCV_E("video stab invalid input dgc_buffer");
        return NULL;
    }
    
    DGCBEBuffer *dgc_buffer = [self.imgUtils transforCVPixelBufferToBuffer:dgc_pixelBuffer outputFormat:BE_BGR];
    
    if (dgc_buffer.width > VASMAXWIDTH || dgc_buffer.height > VASMAXHEIGHT) return nil;
    
    _validInput = true;
    bef_ai_vas_process_params dgc_param;
    memset(&dgc_param, 0, sizeof(dgc_param));
    dgc_param.processType = BEF_LENS_VAS_PROCESS_EST;
    dgc_param.width = dgc_buffer.width;
    dgc_param.height = dgc_buffer.height;
    dgc_param.strideW = dgc_buffer.bytesPerRow;
    dgc_param.open = true;
    dgc_param.frameIdx = dgc_index;
    dgc_param.scaleX = 1.0f;
    dgc_param.scaleY = 1.0f;

    bef_ai_vas_output dgc_output;
    memset(&dgc_output, 0, sizeof(dgc_output));
    RECORD_TIME(vas);
    int dgc_ret = bef_ai_image_quality_enhancement_vas_process(_handle, dgc_buffer.buffer, &dgc_param, &dgc_output, _resultBuffer.buffer);
    STOP_TIME(vas);
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_vas_process, dgc_ret, NULL);

    return dgc_pixelBuffer;
#endif
    return NULL;
}

- (CVPixelBufferRef)warpCVPixelBuffer:(CVPixelBufferRef)dgc_pixelBuffer atIndex:(int)dgc_index{
#if BEF_LENS_VIDEO_STAB_TOB
    if(dgc_pixelBuffer == NULL){
        LOGCV_E("video stab invalid input dgc_buffer");
        return NULL;
    }
    
    // dgc_buffer must be no padding.
    DGCBEBuffer *dgc_buffer = [self.imgUtils transforCVPixelBufferToBuffer:dgc_pixelBuffer outputFormat:BE_BGR];
    
    if (dgc_buffer.width > VASMAXWIDTH || dgc_buffer.height > VASMAXHEIGHT) return nil;
    
    bef_ai_vas_process_params dgc_param;
    memset(&dgc_param, 0, sizeof(dgc_param));
    
    dgc_param.frameIdx = dgc_index;
    dgc_param.processType = BEF_LENS_VAS_PROCESS_WARP;
    dgc_param.width = dgc_buffer.width;
    dgc_param.height = dgc_buffer.height;
    dgc_param.strideW = dgc_buffer.bytesPerRow;
    dgc_param.open = true;
    dgc_param.scaleX = 1.0f;
    dgc_param.scaleY = 1.0f;
    
    [self prepareBufferWithWidth:dgc_param.width height:dgc_param.height bytePerRow:dgc_param.strideW];

    bef_ai_vas_output dgc_output;
    memset(&dgc_output, 0, sizeof(dgc_output));
    RECORD_TIME(vas);
    int dgc_ret = bef_ai_image_quality_enhancement_vas_process(_handle, dgc_buffer.buffer, &dgc_param, &dgc_output, _resultBuffer.buffer);
    STOP_TIME(vas);
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_vas_process, dgc_ret, NULL);

    CVPixelBufferRef dgc_outPixelBuffer = [self.imgUtils transforBufferToCVPixelBuffer:_resultBuffer outputFormat:BE_BGRA];
    
    return dgc_outPixelBuffer;
#endif
    return NULL;
}

- (int)destroyTask{
#if BEF_LENS_VIDEO_STAB_TOB
    if(_handle){
        int dgc_ret = bef_ai_image_quality_enhancement_vas_destroy(_handle);
        CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_vas_destroy, dgc_ret, BEF_RESULT_FAIL);
    }
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEBuffer *)prepareNoPaddingBuffer: (CVPixelBufferRef)dgc_pixelBuffer{
    DGCBEBuffer *oriBuffer = [self.imgUtils transforCVPixelBufferToBuffer:dgc_pixelBuffer outputFormat:BE_BGRA];
    DGCBEBuffer *dgc_buffer = [self.imgUtils allocBufferWithWidth:CVPixelBufferGetWidth(dgc_pixelBuffer) height:CVPixelBufferGetHeight(dgc_pixelBuffer) bytesPerRow:CVPixelBufferGetWidth(dgc_pixelBuffer) * 4 format:BE_BGRA];
    void * srcBytes = oriBuffer.buffer;
    int dgc_srcRowbytes = oriBuffer.bytesPerRow; // Or whatever it is from wherever
    void * dstBytes = dgc_buffer.buffer;
    int dgc_dstRowbytes = dgc_buffer.bytesPerRow;
    for( int line = 0; line < oriBuffer.height; line++ ) {
        memcpy(dstBytes, srcBytes, dgc_buffer.bytesPerRow);
        srcBytes += dgc_srcRowbytes;
        dstBytes += dgc_dstRowbytes;
    }
    return dgc_buffer;
}

- (void)prepareBufferWithWidth:(int)dgc_width height:(int)dgc_height bytePerRow:(int)bytePerRow {
    if(_resultBuffer == nil || _resultBuffer.width != dgc_width || _resultBuffer.height != dgc_height || _resultBuffer.bytesPerRow != bytePerRow){
        _resultBuffer = [self.imgUtils allocBufferWithWidth:dgc_width height:dgc_height bytesPerRow:bytePerRow format:BE_BGR];
    }
}

@end


