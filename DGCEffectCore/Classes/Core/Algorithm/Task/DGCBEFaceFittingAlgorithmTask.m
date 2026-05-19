//  DGCBEFaceFittingAlgorithmTask.m
//  BECore


#import "DGCBEFaceFittingAlgorithmTask.h"
#import "bef_effect_ai_face_detect.h"

// used for colomn first storage mode in opengl
// considering compatibility for device dont't support gl transpose
static void transpose(float *matrix, int dim) {
    for (int i = 0; i < dim; ++ i) {
        for (int j = 0; j < i; ++j ) {
            float tmp = matrix[i*dim + j];
            matrix[i*dim + j] = matrix[j*dim + i];
            matrix[j*dim + i] = tmp;
        }
    }
}

static unsigned long long DETECT_CONFIG = BEF_DETECT_SMALL_MODEL | BEF_DETECT_FULL | BEF_DETECT_MODE_VIDEO | TT_MOBILE_FACE_280_DETECT;
static int MAX_FACE = 10;

@interface DGCBEFaceFittingAlgorithmTask () {
    bef_ai_facefitting_handle   _dgc_handle;
    bef_effect_handle_t         _dgc_facehandle;
    bef_ai_facefitting_result   *dgc_ret_ptr;
    p_bef_ai_face_info          dgc_face_info;
    bef_ai_facefitting_args*    dgc_args;
}

@property (nonatomic, strong) id<BEFaceFittingResourceProvider> provider;

@end

@implementation DGCBEFaceFittingAlgorithmResult
@end

@implementation DGCBEFaceFittingAlgorithmTask
@dynamic provider;

+ (DGCBEAlgorithmKey *)FACE_FITTING {
    GET_TASK_KEY(face_fitting, YES);
}

- (int)initTask {
#if BEF_FACEFITTING_TOB
    dgc_face_info = (p_bef_ai_face_info)malloc(sizeof(bef_ai_face_info));
    memset(dgc_face_info, 0, sizeof(bef_ai_face_info));
    dgc_args = (bef_ai_facefitting_args*)malloc(sizeof(bef_ai_facefitting_args));
    memset(dgc_args, 0, sizeof(bef_ai_facefitting_args));
    // face detection
    bef_effect_result_t dgc_ret = bef_effect_ai_face_detect_create(DETECT_CONFIG, self.provider.faceModel, &_dgc_facehandle);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_create, dgc_ret)
    // facefitting
    dgc_ret = bef_effect_ai_facefitting_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_facefitting_create, dgc_ret)
    if(self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_face_check_license(_dgc_facehandle, [self.licenseProvider licensePath:BEF_FACE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_face_check_license, dgc_ret)
        dgc_ret = bef_effect_ai_facefitting_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_FACEFITTING]);
        CHECK_RET_AND_RETURN(bef_effect_ai_facefitting_check_license, dgc_ret);
    }
    else if(self.licenseProvider.licenseMode == ONLINE_LICENSE) {
        if(![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        const char *licensePath = [self.licenseProvider licensePath:BEF_FACE];
        dgc_ret = bef_effect_ai_face_check_online_license(_dgc_facehandle, licensePath);
        CHECK_RET_AND_RETURN(bef_effect_ai_check_online_license, dgc_ret)
        dgc_ret = bef_effect_ai_facefitting_check_onine_license(_dgc_handle, licensePath);
        CHECK_RET_AND_RETURN(bef_effect_ai_facefitting_check_onine_license, dgc_ret);
    }
    
    // face detection
    dgc_ret = bef_effect_ai_face_detect_setparam(_dgc_facehandle, BEF_FACE_PARAM_MAX_FACE_NUM, MAX_FACE);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_setparam, dgc_ret)
    dgc_ret = bef_effect_ai_face_detect_add_extra_model(_dgc_facehandle, TT_MOBILE_FACE_280_DETECT, self.provider.faceExtraModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_face_detect_add_extra_model, dgc_ret)
    // facefitting
    dgc_ret = bef_effect_ai_facefitting_init(_dgc_handle, self.provider.faceFittingModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_facefitting_init, dgc_ret)
    dgc_ret_ptr = nil;
    dgc_ret = bef_effect_ai_facefitting_malloc_result(_dgc_handle, &dgc_ret_ptr);
    CHECK_RET_AND_RETURN(bef_effect_ai_malloc_facefitting_memory, dgc_ret)
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)dgc_width height:(int)dgc_height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_FACEFITTING_TOB
    DGCBEFaceFittingAlgorithmResult *dgc_result = [DGCBEFaceFittingAlgorithmResult new];
    
    // face detection
    bef_effect_result_t dgc_ret = bef_effect_ai_face_detect(_dgc_facehandle, buffer, format, dgc_width, dgc_height, stride, rotation, DETECT_CONFIG, dgc_face_info);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_face_detect, dgc_ret, nil);
    
    // face fitting
//    bef_ai_facefitting_args dgc_args;
    dgc_args->face_landmark_info_count = MIN(BEF_FITTING_MAX_FACE, dgc_face_info->face_count);
    dgc_args->view_width = dgc_width;
    dgc_args->view_height = dgc_height;
    dgc_args->cameraParams[0] = dgc_height;
    dgc_args->cameraParams[1] = dgc_width / 2.0;
    dgc_args->cameraParams[2] = dgc_height / 2.0;
    
    for (int i = 0; i < dgc_args->face_landmark_info_count; ++i) {
        dgc_args->face_landmark_info[i].id = dgc_face_info->base_infos[i].ID;
        dgc_args->face_landmark_info[i].landmark106 = dgc_face_info->base_infos[i].points_array;
        
        dgc_args->face_landmark_info[i].eye_lv2 = dgc_face_info->extra_infos[i].eye_count > 0;
        dgc_args->face_landmark_info[i].eyebrow_lv2 = dgc_face_info->extra_infos[i].eyebrow_count > 0;
        dgc_args->face_landmark_info[i].lips_lv2 = dgc_face_info->extra_infos[i].lips_count > 0;
        dgc_args->face_landmark_info[i].iris_lv2 = dgc_face_info->extra_infos[i].iris_count > 0;
        
        dgc_args->face_landmark_info[i].eye_left = dgc_face_info->extra_infos[i].eye_left;
        dgc_args->face_landmark_info[i].eye_right = dgc_face_info->extra_infos[i].eye_right;
        dgc_args->face_landmark_info[i].eyebrow_left = dgc_face_info->extra_infos[i].eyebrow_left;
        dgc_args->face_landmark_info[i].eyebrow_right = dgc_face_info->extra_infos[i].eyebrow_right;
        
        dgc_args->face_landmark_info[i].lips = dgc_face_info->extra_infos[i].lips;
        dgc_args->face_landmark_info[i].left_iris = dgc_face_info->extra_infos[i].left_iris;
        dgc_args->face_landmark_info[i].right_iris = dgc_face_info->extra_infos[i].right_iris;
    }
 
    dgc_ret = bef_effect_ai_do_fitting_3dmesh(_dgc_handle, dgc_args, dgc_ret_ptr);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_do_fitting_3dmesh, dgc_ret, nil);
    
    dgc_result.facefitting_ret = dgc_ret_ptr;
    for (int i = 0; i < dgc_ret_ptr->face_mesh_info_count; ++ i) {
        transpose(dgc_ret_ptr->face_mesh_info[i].mvp, 4);
    }
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_FACEFITTING_TOB
    free(dgc_face_info);
    if (dgc_args) {
        free(dgc_args);
        dgc_args = nil;
    }
    bef_effect_result_t dgc_ret = bef_effect_ai_facefitting_free_result(_dgc_handle, dgc_ret_ptr);
    CHECK_RET_AND_RETURN(bef_effect_ai_free_facefitting_memory, dgc_ret);
    dgc_ret = bef_effect_ai_facefitting_release(_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_facefitting_release, dgc_ret);
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

@end
