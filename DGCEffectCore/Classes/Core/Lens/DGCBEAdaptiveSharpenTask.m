//  BELensVideoSR.m
// EffectsARSDK


@import MetalKit;

#import <Foundation/Foundation.h>
#import "DGCBEAdaptiveSharpenTask.h"
#import "bef_ai_image_quality_enhancement_adaptive_sharpen.h"
#import "bef_ai_image_quality_enhancement_public_define.h"
#import "BEImageOpeartion.h"


@interface DGCBEAdaptiveSharpenTask()
    
@property(nonatomic, assign)bef_image_quality_enhancement_handle handle;

@end


@implementation DGCBEAdaptiveSharpenTask
{
    id <MTLDevice> dgc_device;
    bef_ai_asf_init_config dgc_config;
}

#pragma mark -- inittask
-(int) initTask{
#if BEF_LENS_ADAPTIVE_SHARPEN_TOB
    
    int ret = 0;
    if(@available(iOS 11.0, *)) {
        dgc_device = MTLCreateSystemDefaultDevice();
        
        dgc_config.scene_mode = BEF_AI_LENS_ASF_SCENE_MODE_LIVE_PEOPLE;
        dgc_config.context = (__bridge void*)dgc_device;
        dgc_config.input_type = BEF_AI_LENS_PXIELBUFFER_NV12;
        dgc_config.output_type = BEF_AI_LENS_PXIELBUFFER_NV12;
        dgc_config.frame_width = 0;
        dgc_config.frame_height = 0;
        dgc_config.amount = 1.5;
        dgc_config.diff_img_smooth_enable = -1;
        dgc_config.edge_weight_gamma = -1;
        dgc_config.over_ratio = 1.5;
        
        ret = bef_ai_image_quality_enhancement_adaptive_sharpen_create(&_handle,&dgc_config);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_adaptive_sharpen_create, ret)
    }
    else
    {
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_adaptive_sharpen, -1)
    }
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        ret = bef_ai_image_quality_enhancement_adaptive_sharpen_check_license(_handle, [self.provider licensePath:BEF_ADAPTIVE_SHARPEN]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_adaptive_sharpen_check_license, ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE){
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        ret = bef_ai_image_quality_enhancement_adaptive_sharpen_check_online_license(_handle, [self.provider licensePath:BEF_ADAPTIVE_SHARPEN]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_adaptive_sharpen_check_online_license, ret)
    }
    
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}


-(CVPixelBufferRef)processInternal:(CVPixelBufferRef)srcBuffer
{
    #if BEF_LENS_ADAPTIVE_SHARPEN_TOB
    if (srcBuffer == nil)
    {
        return nil;
    }
    CVPixelBufferRef processedBuffer = nil;
    
    CVPixelBufferRef yuv420fbuffer = srcBuffer;
    OSType imageFormat = CVPixelBufferGetPixelFormatType(yuv420fbuffer);
    
    //do the format change if posible, actually we can do more conversion
    //If the input format is 32BGRA, the pipeline is like below:
    // BGRA -> YUV420F -> adaptive_sharpen -> BGRA
    if (imageFormat == kCVPixelFormatType_32BGRA)
    {
        // BGRA -> YUV420F
        DGCBEImageBufferOperation* imageOp = [DGCBEImageBufferOperation sharedInstance];
        yuv420fbuffer =
            [imageOp transforPixelbuffer:srcBuffer destFormat:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    }
    
    imageFormat = CVPixelBufferGetPixelFormatType(yuv420fbuffer);
    if(imageFormat == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange || imageFormat == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
    {
        bef_ai_asf_input sr_input;
        bef_ai_asf_output sr_output;
        int ret;
        
        sr_input.data.buffer = yuv420fbuffer;
        sr_input.type = BEF_AI_LENS_PXIELBUFFER_NV12;
        
        int width = (int)CVPixelBufferGetWidthOfPlane(yuv420fbuffer, 0);
        int height = (int)CVPixelBufferGetHeightOfPlane(yuv420fbuffer, 0);
        if(width != dgc_config.frame_width || height != dgc_config.frame_height)
        {
            
            
            bef_ai_asf_property propertyConfig;
            
            propertyConfig.scene_mode = dgc_config.scene_mode;
            propertyConfig.frame_width = width;
            propertyConfig.frame_height = height;
            propertyConfig.amount = dgc_config.amount;
            propertyConfig.over_ratio = dgc_config.over_ratio;
            propertyConfig.edge_weight_gamma = dgc_config.edge_weight_gamma;
            propertyConfig.diff_img_smooth_enable = dgc_config.diff_img_smooth_enable;
            
            ret = bef_ai_image_quality_enhancement_adaptive_sharpen_set_property(_handle,&propertyConfig);
            //  {zh} 对应 INITING_WAIT 状态  {en} Corresponding INITING_WAIT state
            if (ret == 21) {
                NSLog(@"bef_ai_image_quality_enhancement_adaptive_sharpen_set_property wait for init while setting property");
                return nil;
            }
            CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_adaptive_sharpen_set_property, ret, nil)
            
            dgc_config.frame_width = width;
            dgc_config.frame_height = height;
        }
        
        RECORD_TIME(adaptiveSharpen)
        ret = bef_ai_image_quality_enhancement_adaptive_sharpen_process(_handle, &sr_input, &sr_output);
        STOP_TIME(adaptiveSharpen)
        //    {zh} 错误码为 -69 时可以忽略，但是错误信息还是要打印一下        {en} Error code is -69 can be ignored, but the error message still needs to be printed  
        if (ret == BEF_RESULT_IMAGE_QUALITY_ASP_UNDER_INIT) {
            const char *msg = bef_effect_ai_error_code_get(ret);
            if (msg != NULL) {
                NSLog(@"%s error: %d, %s", "bef_ai_image_quality_enhancement_adaptive_sharpen_process", ret, msg);
            } else {
                NSLog(@"%s error: %d", "bef_ai_image_quality_enhancement_adaptive_sharpen_process", ret);
            }
            return nil;
        }
        CHECK_RET_AND_RETURN_RESULT(bef_ai_image_quality_enhancement_adaptive_sharpen_process, ret, nil)
        
        processedBuffer = sr_output.data.buffer;
    }
    else
    {
        NSLog(@"not support!");
        return nil;
    }
    
    //after the video sr process, it will alwayse be yuv 420 buffer
    //we need to de the left procss by transfer it bgra8888
    return processedBuffer;
#endif
    return nil;
    
}

-(CVPixelBufferRef)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer
{
    CVPixelBufferRef ret = NULL;
    
    @autoreleasepool {
        ret = [self processInternal:srcBuffer];
    }
    
    return ret;
}

-(int)destroyTask{
#if BEF_LENS_ADAPTIVE_SHARPEN_TOB
    int ret = 0;
    
    ret = bef_ai_image_quality_enhancement_adaptive_sharpen_destory(_handle);
    if (ret != 0){
        NSLog(@"bef_ai_image_quality_enhancement_adaptive_sharpen_destory is %d ", ret);
    }
    return ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end
