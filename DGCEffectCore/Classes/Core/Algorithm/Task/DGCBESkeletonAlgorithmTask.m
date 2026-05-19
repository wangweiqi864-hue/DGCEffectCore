//  DGCBESkeletonAlgorithmTask.m
// EffectsARSDK


#import "DGCBESkeletonAlgorithmTask.h"

static int MAX_NUM = 1;

@implementation DGCBESkeletonAlgorithmResult

@end

@interface DGCBESkeletonAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_skeleton_info            *_dgc_skeletonInfo;
}

@property (nonatomic, strong) id<BESkeletonResourceProvider> provider;

@end

@implementation DGCBESkeletonAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)SKELETON {
    GET_TASK_KEY(skeleton, YES)
}

- (int)initTask {
#if BEF_SKELETON_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_skeleton_create(self.provider.skeletonModel, &_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_create, dgc_ret)

    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_skeleton_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKENETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_skeleton_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_SKENETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_skeleton_set_targetnum(_dgc_handle, MAX_NUM);
    CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_set_targetnum, dgc_ret)
    
    _dgc_skeletonInfo = malloc(BEF_AI_MAX_SKELETON_NUM * sizeof(bef_ai_skeleton_info));
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBESkeletonAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_SKELETON_TOB

    DGCBESkeletonAlgorithmResult *dgc_result = [DGCBESkeletonAlgorithmResult new];
    int dgc_validCount = BEF_AI_MAX_SKELETON_NUM;
    RECORD_TIME(detectSkeleton)
    bef_effect_result_t dgc_ret = bef_effect_ai_skeleton_detect(_dgc_handle, buffer, format, widht, height, stride, rotation, &dgc_validCount, &_dgc_skeletonInfo);
    STOP_TIME(detectSkeleton)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_skeleton_detect, dgc_ret, dgc_result)
    dgc_result.skeletonInfo = _dgc_skeletonInfo;
    dgc_result.count = dgc_validCount;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_SKELETON_TOB

    bef_effect_ai_skeleton_destroy(_dgc_handle);
    free(_dgc_skeletonInfo);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBESkeletonAlgorithmTask.SKELETON;
}

@end
