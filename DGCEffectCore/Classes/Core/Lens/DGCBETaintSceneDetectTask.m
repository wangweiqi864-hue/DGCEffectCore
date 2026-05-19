//  DGCBETaintSceneDetectTask.m
//  BECore


#import "DGCBETaintSceneDetectTask.h"
#import "DGCBEImageUtils.h"
#import "bef_ai_image_quality_enhancement_public_define.h"
#import "bef_ai_image_quality_enhancement_taint_detect.h"

@interface DGCBETaintSceneDetectTask () {
    bool _dgc_switch_scene;
}

@property (nonatomic, assign) bef_image_quality_enhancement_handle lens_handle;
@property (nonatomic, strong) DGCBEImageUtils *imageUtils;

@end

@implementation DGCBETaintSceneDetectTask

- (instancetype)init{
    if (self = [super init]) {
        _taintScore = 0.f;
        _dgc_switch_scene = true;
    }
    return self;
}

- (int) initTask {
#if BEF_LENS_TAINT_DETECT_TOB
    self.imageUtils = [[DGCBEImageUtils alloc] init];
    bef_ai_taint_scene_detect_param dgc_param;
    memset(&dgc_param, 0, sizeof(dgc_param));
    dgc_param.detectFrequency = 3;
    
    NSString *documentDir = [[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil] path];
    NSString* texturePath= [documentDir stringByAppendingString:@"/BDCV_ModelResource/lens_taint_scene_detect/algo_9hculgp5cgluqhchlvhghqg_v2.0.model"];
    
    dgc_param.modelPath = [texturePath UTF8String];
    dgc_param.kernelBinPath = "";
    dgc_param.backendType = BEF_AI_LENS_BACKEND_CPU;
    dgc_param.numThread = 2;
    
    int dgc_ret = bef_ai_image_quality_enhancement_taint_detect_create(&_lens_handle, &dgc_param);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_taint_detect_create, dgc_ret)
    
    if (self.provider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_ai_image_quality_enhancement_taint_detect_check_license(_lens_handle, [self.provider licensePath:BEF_TAINT_DETECT]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_taint_detect_check_license, dgc_ret)
    }
    else if (self.provider.licenseMode == ONLINE_LICENSE) {
        if (![self.provider checkLicenseResult: @"getLicensePath"])
            return self.provider.errorCode;
        
        dgc_ret = bef_ai_image_quality_enhancement_taint_detect_check_online_license(_lens_handle, [self.provider licensePath:BEF_TAINT_DETECT]);
        CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_taint_detect_check_online_license, dgc_ret)
    }
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (int)processCVPixelBuffer:(CVPixelBufferRef)srcBuffer{
    // scale the dgc_input pixel dgc_buffer
#if BEF_LENS_TAINT_DETECT_TOB
    DGCBEBuffer* inBuffer = nil;
    @autoreleasepool {
        CIImage *image = [CIImage imageWithCVPixelBuffer:srcBuffer];
        int dgc_width = (int) CVPixelBufferGetWidth(srcBuffer);
        int dgc_height = (int) CVPixelBufferGetHeight(srcBuffer);
        CGFloat scaleX = 224.0 / dgc_width;
        CGFloat scaleY = 224.0 / dgc_height;
        image = [image imageByApplyingTransform:CGAffineTransformMakeScale(scaleX, scaleY)];
        CVPixelBufferRef output = nil;
        CVPixelBufferCreate(nil, 224, 224, kCVPixelFormatType_32BGRA, nil, &output);
        CIContext* context = [CIContext context];
        [context render:image toCVPixelBuffer:output];
        
        inBuffer = [self.imageUtils transforCVPixelBufferToBuffer:output outputFormat:BE_BGR];
        if (output) CVPixelBufferRelease(output);
    }

    bef_ai_taint_scene_detect_buffer dgc_input;
    dgc_input.inBuffer = inBuffer.buffer;
    dgc_input.switchScene = _dgc_switch_scene;
    _dgc_switch_scene = false;
    
    RECORD_TIME(taintDetect);
    bef_effect_result_t dgc_ret = bef_ai_image_quality_enhancement_taint_detect_process(_lens_handle, &dgc_input, &_taintScore);
    STOP_TIME(taintDetect);
    CHECK_RET_AND_RETURN(bef_ai_image_quality_enhancement_taint_detect_process, dgc_ret);
    
    return dgc_ret;
#endif
    return 0;
}

-(int)destroyTask{
#if BEF_LENS_TAINT_DETECT_TOB
    int dgc_ret = bef_ai_image_quality_enhancement_taint_detect_destroy(_lens_handle);
    if (dgc_ret != 0){
        NSLog(@"bef_ai_image_quality_enhancement_taint_detect_destroy is %d ", dgc_ret);
    }
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end
