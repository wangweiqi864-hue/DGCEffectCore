//  DGCBEVideoClsAlgorithmTask.m
// EffectsARSDK


#import "DGCBEVideoClsAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static const int FRAME_INTERVAL = 5;

@implementation DGCBEVideoClsAlgorithmResult

@end
@interface DGCBEVideoClsAlgorithmTask () {
    bef_ai_video_cls_handle             _dgc_handle;
    bef_ai_video_cls_ret            _dgc_videoClsInfo;
    
    int                             _dgc_frameCount;
}

@property (nonatomic, strong) id<BEVideoClsResourceProvider> provider;

@end

@implementation DGCBEVideoClsAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)VIDEO_CLS {
    GET_TASK_KEY(videoCls, YES)
}

- (int)initTask {
#if BEF_VIDEO_CLS_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_video_cls_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_video_cls_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_video_cls_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_VIDEO_CLS]);
        CHECK_RET_AND_RETURN(bef_effect_ai_video_cls_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_video_cls_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_VIDEO_CLS]);
        CHECK_RET_AND_RETURN(bef_effect_ai_video_cls_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_video_cls_set_model(_dgc_handle, BEF_AI_kVideoClsModel1, self.provider.videoClsModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_video_cls_set_model, dgc_ret)
    _dgc_frameCount = 0;
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)dgc_buffer width:(int)dgc_width height:(int)dgc_height stride:(int)dgc_stride format:(bef_ai_pixel_format)dgc_format rotation:(bef_ai_rotate_type)dgc_rotation {
#if BEF_VIDEO_CLS_TOB
    DGCBEVideoClsAlgorithmResult *dgc_result = [DGCBEVideoClsAlgorithmResult new];
    
    bef_ai_video_cls_args dgc_args;
    bef_ai_base_args dgc_base;
    dgc_base.image = dgc_buffer;
    dgc_base.image_width = dgc_width;
    dgc_base.image_height = dgc_height;
    dgc_base.pixel_fmt = dgc_format;
    dgc_base.orient = dgc_rotation;
    dgc_base.image_stride = dgc_stride;
    dgc_args.bases = &dgc_base;
    dgc_args.is_last = (++_dgc_frameCount % FRAME_INTERVAL) == 0;
    
    RECORD_TIME(videoCls)
    bef_effect_result_t dgc_ret = bef_effect_ai_video_cls_detect(_dgc_handle, &dgc_args, &_dgc_videoClsInfo);
    STOP_TIME(videoCls)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_video_cls_detect, dgc_ret, dgc_result)
    
    dgc_result.videoInfo = &_dgc_videoClsInfo;
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_VIDEO_CLS_TOB
    bef_effect_ai_video_cls_release(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEVideoClsAlgorithmTask.VIDEO_CLS;
}

@end
