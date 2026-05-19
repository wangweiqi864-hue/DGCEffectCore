//  DGCBEDynamicGestureAlgorithmResult.m
//  BECore


#import "DGCBEBachSkeletonAlgorithmTask.h"

@implementation DGCBEBachSkeletonAlgorithmResult

@end

@interface DGCBEBachSkeletonAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_bach_skeleton_info       *_dgc_skeletonInfo;
}

@property (nonatomic, strong) id<BEBachSkeletonResourceProvider> provider;

@end

@implementation DGCBEBachSkeletonAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)BACH_SKELETON {
    GET_TASK_KEY(bachSkeleton, YES)
}

- (int)initTask {
#if BEF_BACH_SKELETON_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_bach_skeleton_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_bach_skeleton_create, dgc_ret)

    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_bach_skeleton_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_BACH_SKELETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_bach_skeleton_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_bach_skeleton_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_BACH_SKELETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_bach_skeleton_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_bach_skeleton_init(_dgc_handle, self.provider.bachSkeletonModel);
    
    _dgc_skeletonInfo = malloc(BEF_AI_MAX_BACH_SKELETON_NUM * sizeof(bef_ai_bach_skeleton_info));
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEBachSkeletonAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_BACH_SKELETON_TOB

    DGCBEBachSkeletonAlgorithmResult *dgc_result = [DGCBEBachSkeletonAlgorithmResult new];
    int dgc_validCount = BEF_AI_MAX_BACH_SKELETON_NUM;
    RECORD_TIME(detectSkeleton)
    bef_effect_result_t dgc_ret = bef_effect_ai_bach_skeleton_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &dgc_validCount, &_dgc_skeletonInfo);
    STOP_TIME(detectSkeleton)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_bach_skeleton_detect, dgc_ret, dgc_result)
    dgc_result.skeletonInfo = _dgc_skeletonInfo;
    dgc_result.count = dgc_validCount;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_BACH_SKELETON_TOB
    free(_dgc_skeletonInfo);
    return bef_effect_ai_bach_skeleton_release(_dgc_handle);
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEBachSkeletonAlgorithmTask.BACH_SKELETON;
}

@end
