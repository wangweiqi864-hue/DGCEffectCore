//  DGCBEVideoFrameInsertTask.m
//  BECore


#import "DGCBEVideoFrameInsertTask.h"
#import "bef_ai_image_quality_enhancement_vfi.h"

@interface DGCBEVideoFrameInsertTask()

@property(nonatomic, assign)bef_image_quality_enhancement_handle handle;

@end

@implementation DGCBEVideoFrameInsertTask

- (int) initTask {
#if BEF_LENS_VIDEO_VIF_TOB
    bef_ai_vfi_init_config config;
    memset(&config, 0, sizeof(config));
    
    
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    NSString* texturePath= [documentDir stringByAppendingString:@"/BDCV_ModelResource/video_frame_insertion/umvfi.metallib"];
    
    config.kernelBinPath = [texturePath UTF8String];
    config.type = bef_ai_lens_vfi_um;
    config.dataType = bef_ai_lens_vfi_rgba8888_buffer;
    config.level = BEF_AI_LENS_POWER_LEVEL_HIGH;
    
    int ret = bef_ai_image_quality_enhancement_vfi_create(&_handle, &config);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vfi_create, ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        ret = bef_ai_image_quality_enhancement_vfi_check_license(_handle, [self.provider licensePath:BEF_VFI]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vfi_check_license, ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE) {
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        ret = bef_ai_image_quality_enhancement_vfi_check_online_license(_handle, [self.provider licensePath:BEF_VFI]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_vfi_check_online_license, ret)
    }
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)frontBuffer nextCVPixelBuffer:(CVPixelBufferRef)backBuffer withRatio:(float)ratio Update:(bool)update{
#if BEF_LENS_VIDEO_VIF_TOB
    if (frontBuffer == nil || backBuffer == nil) return nil;
    
    ratio = MAX(MIN(ratio, 1.0), 0.0);
    bef_ai_vfi_process_config config;
    config.textureIdP = -1;
    config.width = (int)CVPixelBufferGetWidth(frontBuffer);
    config.height = (int)CVPixelBufferGetHeight(frontBuffer);
    config.strideW = (int)CVPixelBufferGetBytesPerRow(frontBuffer);
    config.strideH = config.height;
    config.open = 1;
    config.flag = update ? 1 : 2;
    config.timeStamp = ratio;
    config.scaleX = 1.0f;
    config.scaleY = 1.0f;
    config.buffer = frontBuffer;
    config.backBuffer = backBuffer;
    
//    if (fabs(ratio) < 1e-6) return frontBuffer;
//    if (fabs(ratio - 1.0) < 1e-6) return backBuffer;
    CVPixelBufferRef processedBuffer = nil;
    bef_ai_lens_vfi_data output;
    memset(&output, 0, sizeof(output));
    RECORD_TIME(video_frame_insertion);
    int ret = bef_ai_image_quality_enhancement_vfi_process(_handle, &config, &output);
    STOP_TIME(video_frame_insertion);
    // Lens see this as no need to do vfi, thus this is not a error actually
    if (ret == BEF_RESULT_IMAGE_QUALITY_VFI_NO_EXECUTION) {
        const char *msg = bef_effect_ai_error_code_get(ret);
        if (msg != nil) {
            NSLog(@"%s error: %d, %s", "bef_ai_image_quality_enhancement_vfi_process", ret, msg);
        } else {
            NSLog(@"%s error: %d", "bef_ai_image_quality_enhancement_vfi_process", ret);
        }
        return nil;
    }
    
    CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_vfi_process, ret, nil)
    processedBuffer = (CVPixelBufferRef)output.buffer;
    NSAssert(processedBuffer, @"null result");
    
    return processedBuffer;
#endif
    return nil;
}

- (int) destroyTask {
#if BEF_LENS_VIDEO_VIF_TOB
    int ret = 0;
    ret = bef_ai_image_quality_enhancement_vfi_destroy(_handle);
    if (ret != 0) {
        NSLog(@"bef_ai_image_quality_enhancement_vfi_destroy is %d ", ret);
    }
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end


