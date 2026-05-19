//  DGCBEDynamicGestureAlgorithmResult.m
//  BECore


#import "DGCBESkinSegmentationAlgorithmTask.h"

@implementation DGCBESkinSegmentationAlgorithmResult

@end
@interface DGCBESkinSegmentationAlgorithmTask () {
    bef_effect_handle_t           _dgc_handle;
    bef_ai_skin_segmentation_ret  _dgc_skinSegInfo;
}

@property (nonatomic, strong) id<BESkinSegmentationResourceProvider> provider;

@end

@implementation DGCBESkinSegmentationAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)SKIN_SEGMENTATION {
    GET_TASK_KEY(skinSegmentation, YES)
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (int)initTask {
#if BEF_SKIN_SEGMENTATION_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_skin_segmentation_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_skin_segmentation_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_skin_segmentation_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKIN_SEGMENTATION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skin_segmentation_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_skin_segmentation_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKIN_SEGMENTATION]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skin_segmentation_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_skin_segmentation_init(_dgc_handle, self.provider.skinSegmentationModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_skin_segmentation_init, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBESkinSegmentationAlgorithmResult *)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_SKIN_SEGMENTATION_TOB
    DGCBESkinSegmentationAlgorithmResult *dgc_result = [DGCBESkinSegmentationAlgorithmResult new];
    RECORD_TIME(skinSegmentation)
    bef_effect_result_t dgc_ret = bef_effect_ai_skin_segmentation_detect(_dgc_handle, buffer, format, width, height, stride, rotation, &_dgc_skinSegInfo);
    STOP_TIME(skinSegmentation)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_skin_segmentation_detect, dgc_ret, dgc_result);
    
    dgc_result.skinSegInfo = &_dgc_skinSegInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_SKIN_SEGMENTATION_TOB

    return bef_effect_ai_skin_segmentation_release(_dgc_handle);
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBESkinSegmentationAlgorithmTask.SKIN_SEGMENTATION;
}

@end
