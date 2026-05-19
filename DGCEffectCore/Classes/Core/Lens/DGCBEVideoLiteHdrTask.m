//
//  DGCBEVideoLiteHdrTask.m
//  BECore
//

#import <Foundation/Foundation.h>
#import "DGCBEVideoLiteHdrTask.h"
#import "bef_ai_image_quality_enhancement_video_hdr.h"
#import "DGCBELensResourceHelper.h"

@interface DGCBEVideoLiteHdrTask()
    
@property(nonatomic, assign)bef_image_quality_enhancement_handle handle;
@property(nonatomic, assign)bool                            first_frame;

@end

@implementation DGCBEVideoLiteHdrTask
{
    bef_ai_hdr_init_config dgc_config;
}

#pragma mark -- init task

-(int) initTask{
#if BEF_LENS_VIDEO_HDR_TOB
    _first_frame = true;
    int ret = 0;
    if(@available(iOS 11.0, *)) {
        DGCBELensResourceHelper *resourceHelper = [DGCBELensResourceHelper new];

        dgc_config.context = NULL;
        dgc_config.maxWidth = 4096;
        dgc_config.maxHeight = 4096;
        dgc_config.backendType = BEF_AI_LENS_BACKEND_GPU;
        dgc_config.perNum = 6;
        dgc_config.algType = BEF_HDR_TYPE_LITE_V8;
        dgc_config.isExtOESTexture = false;
        dgc_config.imgLutPath = [resourceHelper videoHdrLiteHdrPath];
        dgc_config.skinLutPath = NULL;
        dgc_config.isNeedSkinSeg = false;
        dgc_config.isCover = false;
        dgc_config.pixelFmt = BEF_AI_PIX_FMT_BGRA8888;
        ret = bef_ai_image_quality_enhancement_video_lite_hdr_create(&_handle, &dgc_config);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_lite_hdr_create, ret)
    }
    else
    {
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_adaptive_sharpen, -1)
    }
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        ret = bef_ai_image_quality_enhancement_video_lite_hdr_check_license(_handle, [self.provider licensePath:BEF_VIDEO_HDR_LITE]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_lite_hdr_check_license, ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE){
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        ret = bef_ai_image_quality_enhancement_video_lite_hdr_check_online_license(_handle, [self.provider licensePath:BEF_VIDEO_HDR_LITE]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_video_lite_hdr_check_online_license, ret)
    }
    
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}


-(CVPixelBufferRef)processInternal:(CVPixelBufferRef)srcBuffer
{
#if BEF_LENS_VIDEO_HDR_TOB
    bef_ai_hdr_lite_param param;
    bef_ai_hdr_lite_frame_info frameInfo;
    bef_ai_hdr_lite_input input;
    bef_ai_hdr_lite_output output;
    
    frameInfo.isFirstFrame = _first_frame; //  {zh} 是否为视频第一帧（设置为true表示重置，清楚算法缓存）  {en} Whether it is the first frame of the video (set to true to indicate reset, clear algorithm cache)
    _first_frame = false;
    frameInfo.isDay = true;
    frameInfo.isProtectFace = true;
    frameInfo.isAFS = true;
    frameInfo.faceList = NULL;
    frameInfo.faceNum = 0;
    frameInfo.faceLuminanceTarget = -1;
    frameInfo.faceLuminanceFactor = -1.0f;
    frameInfo.luminanceTarget = -1;
    frameInfo.luminanceFactor = -1.0f;
    frameInfo.contrast = -1.0f;
    frameInfo.saturation = -1.0f;
    frameInfo.sharpenStrength = -1.0f;
    frameInfo.enhanceStrength = 1.0f;
    
    param.textureId = 0;
    param.open = true;
    param.stMatrix = NULL;
    CVPixelBufferLockBaseAddress(srcBuffer, kCVPixelBufferLock_ReadOnly);
    size_t width = CVPixelBufferGetWidth(srcBuffer);
    size_t height = CVPixelBufferGetHeight(srcBuffer);
    CVPixelBufferUnlockBaseAddress(srcBuffer, 0);
    
    param.width = width;
    param.height = height;
    param.info = &frameInfo;
    param.skinSegPtr = NULL;
    
    input.data.buffer = srcBuffer;

    int ret = bef_ai_image_quality_enhancement_video_lite_hdr_process(_handle, &param, &input, &output);
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_adaptive_sharpen_process, ret, nil)
    
    return output.data.buffer;
#endif
    return nil;
    
}

-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer
{
    CVPixelBufferRef ret = NULL;
    
    
    ret = [self processInternal:srcBuffer];
    
    return ret;
}

- (void)resetFirstFrame {
    _first_frame = true;
}


-(int)destroyTask{
#if BEF_LENS_VIDEO_HDR_TOB
    int ret = 0;
    
    ret = bef_ai_image_quality_enhancement_video_lite_hdr_destory(_handle);
    if (ret != 0){
        NSLog(@"bef_ai_image_quality_enhancement_video_lite_hdr_destory is %d ", ret);
    }
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end


