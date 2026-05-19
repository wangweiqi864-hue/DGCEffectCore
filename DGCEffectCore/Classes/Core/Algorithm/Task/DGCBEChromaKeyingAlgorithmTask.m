//  DGCBEDynamicGestureAlgorithmResult.m
//  BECore


#import "DGCBEChromaKeyingAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

@implementation DGCBEChromaKeyingAlgorithmResult

@end
@interface DGCBEChromaKeyingAlgorithmTask () {
    bef_effect_handle_t      _dgc_handle;
    bef_ai_chroma_keying_ret _dgc_chromKeyingInfo;
}

@property (nonatomic, strong) id<BEChromaKeyingResourceProvider> provider;

@end

@implementation DGCBEChromaKeyingAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)CHROMA_KEYING {
    GET_TASK_KEY(chromaKeying, YES)
}

+ (DGCBEAlgorithmKey *)CHROMA_KEYING_SOFT {
    GET_TASK_KEY(chromaKeyingSoft, NO)
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (int)initTask {
#if BEF_CHROMA_KEYING_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_chroma_keying_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_chroma_keying_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_chroma_keying_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_CHROMA_KEYING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_chroma_keying_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_chroma_keying_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_CHROMA_KEYING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_chroma_keying_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_chroma_keying_init(_dgc_handle, self.provider.chromaKeyingModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_chroma_keying_init, dgc_ret)
    //  {zh} 设置绿幕抠图算法处理参数  {en} Set green screen cutout algorithm processing parameters
    bef_effect_ai_chroma_keying_set_processParam(0.25, 0.5, 0.1, 0.5, 1.0);
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEChromaKeyingAlgorithmResult *)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_CHROMA_KEYING_TOB
    DGCBEChromaKeyingAlgorithmResult *dgc_result = [DGCBEChromaKeyingAlgorithmResult new];


    unsigned char *data = NULL;
    bool imageWithPadding = (stride != width * 4);
    if (imageWithPadding) {
        data = malloc(width * height * 4 * sizeof(unsigned char));
        for (int i = 0; i < height; ++i) {
            memcpy(data + i * width * 4, buffer + i * stride, width * 4);
        }
        stride = width * 4;
    }
    
    bool soft = [self boolConfig:DGCBEChromaKeyingAlgorithmTask.CHROMA_KEYING_SOFT orDefault:NO];
    RECORD_TIME(chromaKeying)
    bef_effect_result_t dgc_ret = bef_effect_ai_chroma_keying_detect(_dgc_handle, imageWithPadding ? data : buffer, format, width, height, stride, rotation, &_dgc_chromKeyingInfo, soft);
    STOP_TIME(chromaKeying)
    if (imageWithPadding) free(data);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_chroma_keying_detect, dgc_ret, dgc_result)
    dgc_result.chromaKeyingInfo = &_dgc_chromKeyingInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_CHROMA_KEYING_TOB
    return bef_effect_ai_chroma_keying_release(_dgc_handle);
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEChromaKeyingAlgorithmTask.CHROMA_KEYING;
}

@end
