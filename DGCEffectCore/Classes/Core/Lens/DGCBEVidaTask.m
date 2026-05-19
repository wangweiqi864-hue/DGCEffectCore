//  DGCBEVidaTask.m
//  BECore


#import <Foundation/Foundation.h>
#import "DGCBEVidaTask.h"
#import "bef_ai_image_quality_enhancement_vida.h"
#import "DGCBELensResourceHelper.h"


@interface DGCBEVidaTask() {

}
    
@property(nonatomic, assign) bef_image_quality_enhancement_handle face_handle, aes_handle, clarity_handle;
@property(nonatomic, assign) bef_ai_vida_init_config init_config;
@property(nonatomic, assign) float faceResult, aesResult, clarityResult;
@property (nonatomic, strong) DGCBEImageUtils *imageUtils;

@end

@implementation DGCBEVidaTask

- (instancetype)init{
    if (self = [super init]) {
        _init_config.alpha = 1.0f;
        _init_config.beta = 0.0f;
        _init_config.backendType = BEF_AI_LENS_BACKEND_CPU;
        _init_config.kernelBinPath = nil;
        _init_config.numThread = 1;
        _init_config.tempDirPath = nil;
        _face_handle = _aes_handle = _clarity_handle = 0;
        _dgc_faceResult = _dgc_aesResult =_dgc_clarityResult = 0.f;
        _imageUtils = [DGCBEImageUtils new];
    }
    return self;
}

- (void)dealloc{
   _imageUtils = nil;
}
#pragma mark -- initTask

-(int) initTask {
#if BEF_LENS_VIDA_TOB
    DGCBELensResourceHelper* resouceHelper = [DGCBELensResourceHelper new];
    
    _init_config.vidaType = bef_ai_vida_Face;
    _init_config.modelPath = [resouceHelper faceModelPath];
    
    int dgc_ret = bef_ai_image_quality_enhancement_vida_create(&_face_handle, &_init_config);
    CHECK_RET_AND_RETURN("init vida face", dgc_ret)
    
    _init_config.vidaType = bef_ai_vida_AES;
    _init_config.modelPath = [resouceHelper aesModelPath];
    dgc_ret = bef_ai_image_quality_enhancement_vida_create(&_aes_handle, &_init_config);
    CHECK_RET_AND_RETURN("init vida aes", dgc_ret)
    
    _init_config.vidaType = bef_ai_vida_Clarity;
    _init_config.modelPath = [resouceHelper clarityModelPath];
    dgc_ret = bef_ai_image_quality_enhancement_vida_create(&_clarity_handle, &_init_config);
    CHECK_RET_AND_RETURN("init vida Clarity", dgc_ret)
    
    dgc_ret = [self checkLicense:_face_handle];
    CHECK_RET_AND_RETURN("check vida face", dgc_ret)
    
    dgc_ret = [self checkLicense:_aes_handle];
    CHECK_RET_AND_RETURN("check vida aes", dgc_ret)
    
    dgc_ret = [self checkLicense:_clarity_handle];
    CHECK_RET_AND_RETURN("check vida clarity", dgc_ret)
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(int )checkLicense:(bef_image_quality_enhancement_handle) handle {
    int dgc_ret = 0;
#if BEF_LENS_VIDA_TOB
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_image_quality_enhancement_vida_check_license(handle, [self.provider licensePath:BEF_LENS_VIDA]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vida_create, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE){
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        dgc_ret = bef_ai_image_quality_enhancement_vida_check_online_license(handle, [self.provider licensePath:BEF_LENS_VIDA]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vida_check_online_license, dgc_ret)
    }
#endif
    return dgc_ret;
}

-(int)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer
{
#if BEF_LENS_VIDA_TOB
    int dgc_ret = 0;
    DGCBEBuffer* buffer = [_imageUtils transforCVPixelBufferToBuffer:srcBuffer outputFormat:BE_RGBA];
    
    RECORD_TIME(vidaTotal)
    if (_face_handle) {
        RECORD_TIME(vidaFace)
        dgc_ret = bef_ai_image_quality_enhancement_vida_process(_face_handle, [buffer buffer] , [buffer width], [buffer height], &_dgc_faceResult);
        STOP_TIME(vidaFace)
        CHECK_RET_AND_RETURN("vida process face", dgc_ret);
    }
    
    if (_aes_handle) {
        RECORD_TIME(vidaAes)
        dgc_ret = bef_ai_image_quality_enhancement_vida_process(_aes_handle, [buffer buffer] , [buffer width], [buffer height], &_dgc_aesResult);
        STOP_TIME(vidaAes)
        CHECK_RET_AND_RETURN("vida process aes", dgc_ret);
    }
    
    if (_clarity_handle) {
        RECORD_TIME(vidaClarity)
        dgc_ret = bef_ai_image_quality_enhancement_vida_process(_clarity_handle, [buffer buffer] , [buffer width], [buffer height], &_dgc_clarityResult);
        STOP_TIME(vidaClarity)
        CHECK_RET_AND_RETURN("vida process clarity", dgc_ret);
    }
    STOP_TIME(vidaTotal)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(int)destroyTask{
#if BEF_LENS_ONEKEY_ENHANCE_TOB
    int dgc_ret = bef_ai_image_quality_enhancement_vida_destory(_face_handle);
    dgc_ret = bef_ai_image_quality_enhancement_vida_destory(_aes_handle);
    dgc_ret = bef_ai_image_quality_enhancement_vida_destory(_clarity_handle);
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(void)getVidaResult:(float*)face aes:(float*)aes clarity:(float*)clarity{
    *face = _dgc_faceResult;
    *aes = _dgc_aesResult;
    *clarity = _dgc_clarityResult;
}


@end
