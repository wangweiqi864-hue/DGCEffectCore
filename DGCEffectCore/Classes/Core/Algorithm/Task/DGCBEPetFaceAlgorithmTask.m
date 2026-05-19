//  DGCBEPetFaceAlgorithmTask.m
// EffectsARSDK


#import "DGCBEPetFaceAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static long long DETECT_CONFIG = BEF_DetCat|BEF_DetDog;
static int MAX_NUM = AI_MAX_PET_NUM;

@implementation DGCBEPetFaceAlgorithmResult

@end
@interface DGCBEPetFaceAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    bef_ai_pet_face_result          _dgc_petFaceInfo;
}

@property (nonatomic, strong) id<BEPetFaceResourceProvider> provider;

@end

@implementation DGCBEPetFaceAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)PET_FACE {
    GET_TASK_KEY(petFace, YES)
}

- (int)initTask {
#if BEF_PET_FACE_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_pet_face_create(self.provider.petFaceModelPath, DETECT_CONFIG, MAX_NUM, &_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_pet_face_create, dgc_ret)
    
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_pet_face_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_PET_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_pet_face_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;

        dgc_ret = bef_effect_ai_pet_face_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_PET_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_pet_face_check_online_license, dgc_ret)
    }
    
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_PET_FACE_TOB

    DGCBEPetFaceAlgorithmResult *dgc_result = [DGCBEPetFaceAlgorithmResult new];
    RECORD_TIME(petFace)
    bef_effect_result_t dgc_ret = bef_effect_ai_pet_face_detect(_dgc_handle, buffer, format, width, height, stride, rotation, &_dgc_petFaceInfo);
    STOP_TIME(petFace)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_pet_face_detect, dgc_ret, dgc_result)
    dgc_result.petFaceInfo = &_dgc_petFaceInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_PET_FACE_TOB
    bef_effect_ai_pet_face_release(_dgc_handle);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEPetFaceAlgorithmTask.PET_FACE;
}

@end
