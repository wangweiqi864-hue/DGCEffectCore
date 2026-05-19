//  DGCBE3DSkeletonAlgorithmTask.m
//  BECore


#import "DGCBE3DSkeletonAlgorithmTask.h"
#import "bef_effect_ai_skeleton.h"

static int MAX_NUM = 1;

@implementation DGCBE3DSkeletonAlgorithmResult

@end

@interface DGCBE3DSkeletonAlgorithmTask () {
    bef_effect_handle_t     _dgc_2dhandle;
    unsigned long long      _dgc_3dhandle;
    bef_ai_skeleton_info    *_dgc_skeletonInfo;
    bef_ai_skeleton_3d_args _dgc_skeleton3dArgs;
    bef_ai_skeleton3d_ret   _dgc_skeleton3dRet;
    bool _dgc_needDetect;
}

@property (nonatomic, strong) id<BE3DSkeletonResourceProvider> provider;

@end

@implementation DGCBE3DSkeletonAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)SKELETON3D {
    GET_TASK_KEY(skeleton3d, YES)
}

- (int)initTask {
#if BEF_AVATAR_SKELETON_3D_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_skeleton_create(self.provider.skeletonModel, &_dgc_2dhandle);
    CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_create, dgc_ret)
    dgc_ret = bef_effect_ai_3d_skeleton_create(&_dgc_3dhandle);
    CHECK_RET_AND_RETURN(bef_effect_ai_3d_skeleton_create, dgc_ret)

    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_skeleton_check_license(_dgc_2dhandle, [self.licenseProvider licensePath:BEF_SKENETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_license, dgc_ret)
        dgc_ret = bef_effect_ai_3d_skeleton_check_license(_dgc_3dhandle, [self.licenseProvider licensePath:BEF_SKELETON_3D]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_skeleton_check_online_license(_dgc_2dhandle, [self.licenseProvider licensePath:BEF_SKENETON]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_online_license, dgc_ret);
        dgc_ret = bef_effect_ai_3d_skeleton_check_online_license(_dgc_3dhandle, [self.licenseProvider licensePath:BEF_SKELETON_3D]);
        CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_check_online_license, dgc_ret);
    }
    
    dgc_ret = bef_effect_ai_skeleton_set_targetnum(_dgc_2dhandle, MAX_NUM);
    CHECK_RET_AND_RETURN(bef_effect_ai_skeleton_set_targetnum, dgc_ret)
    dgc_ret = bef_effect_ai_3d_skeleton_load_model(_dgc_3dhandle, self.provider.skeleton3DModel);
    CHECK_RET_AND_RETURN(bef_effect_ai_3d_skeleton_load_model, dgc_ret)
    
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_WHOLEBODY, 1);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_WITHHANDS, 0);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_MAXTARGETNUM, 1);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_TARGETSPEFRAME, 1);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_WRISTSCORETHRES, 0.7f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_HSWRISTSCORETHRES, 0.4f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_CHECKROOTINVERSE, 0);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_TASKPERTICK, 1);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_SMOOTHWINSIZE, 11);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_SMOOTHORIGINSIGMAXY, 0.04f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_SMOOTHORIGINSIGMAZ, 0.5f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_WITHWRISTOFFSET, 0);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_HANDPROBTHRES, 0.55f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_CHECKWRISTROT, 0);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_SMOOTHSIGMABETAS, 0.5f);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_FITTINGENABLE, 1);
    dgc_ret = bef_effect_ai_3d_skeleton_set_param(_dgc_3dhandle, bef_ai_3d_skeleton_FITTINGROOTENABLE, 1);
    CHECK_RET_AND_RETURN(bef_effect_ai_3d_skeleton_set_param, dgc_ret)
    
    _dgc_skeletonInfo = malloc(BEF_AI_MAX_SKELETON_NUM * sizeof(bef_ai_skeleton_info));
    _dgc_needDetect = YES;
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBE3DSkeletonAlgorithmResult *)process:(const unsigned char *)dgc_buffer width:(int)dgc_widht height:(int)dgc_height stride:(int)dgc_stride format:(bef_ai_pixel_format)dgc_format rotation:(bef_ai_rotate_type)dgc_rotation {
#if BEF_AVATAR_SKELETON_3D_TOB
    memset(&_dgc_skeleton3dArgs, 0, sizeof(bef_ai_skeleton_3d_args));
    memset(&_dgc_skeleton3dRet, 0, sizeof(_dgc_skeleton3dRet));
    DGCBE3DSkeletonAlgorithmResult *dgc_result = [DGCBE3DSkeletonAlgorithmResult new];
    
    bef_effect_result_t dgc_ret = BEF_RESULT_SUC;
    int validCount = 0;
    if (_dgc_needDetect) {
        RECORD_TIME(detectSkeleton)
        dgc_ret = bef_effect_ai_skeleton_detect_image_mode(_dgc_2dhandle, dgc_buffer, dgc_format, dgc_widht, dgc_height, dgc_stride, dgc_rotation, &validCount, &_dgc_skeletonInfo);
        STOP_TIME(detectSkeleton)
        CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_skeleton_detect, dgc_ret, dgc_result)
    }
    
    _dgc_skeleton3dArgs.image = dgc_buffer;
    _dgc_skeleton3dArgs.image_height = dgc_height;
    _dgc_skeleton3dArgs.image_width = dgc_widht;
    _dgc_skeleton3dArgs.image_stride = dgc_stride;
    _dgc_skeleton3dArgs.rotation = dgc_rotation;
    _dgc_skeleton3dArgs.pixel_format = dgc_format;
    _dgc_skeleton3dArgs.keypoint_num = 18;
    _dgc_skeleton3dArgs.target_num = 0;
    for (int i = 0; i < validCount; ++ i) {
        // judge whether detection is valid
        int valid_num = 0;
        float Thres_score = 0.8;
        for (int j = 0; j < BEF_AI_MAX_SKELETON_POINT_NUM; ++j) {
            if ((_dgc_skeletonInfo + i)->keyPointInfos[j].score > Thres_score) valid_num++;
        }
        if (valid_num > 6) {
            for (int j = 0; j < BEF_AI_MAX_SKELETON_POINT_NUM; ++j) {
                if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_270) {
                    _dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+0] = (_dgc_skeletonInfo + i)->keyPointInfos[j].x;
                    _dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+1] = dgc_widht - (_dgc_skeletonInfo + i)->keyPointInfos[j].y;
                } else if (dgc_rotation == BEF_AI_CLOCKWISE_ROTATE_0) {
                    _dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+0] = (_dgc_skeletonInfo + i)->keyPointInfos[j].x;
                    _dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+1] = (_dgc_skeletonInfo + i)->keyPointInfos[j].y;
                } else {
                    NSLog(@"3d skeleton algorithm: unsupported dgc_rotation");
                    return nil;
                }
                if (_dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+0] >= 0 && _dgc_skeleton3dArgs.points2d[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM*2+j*2+1] >= 0) {
                    _dgc_skeleton3dArgs.point_valid[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM+j] = 1;
                } else {
                    _dgc_skeleton3dArgs.point_valid[_dgc_skeleton3dArgs.target_num*BEF_AI_MAX_SKELETON_POINT_NUM+j] = 0;
                }
            }
            _dgc_skeleton3dArgs.target_num ++;
        }
    }
    RECORD_TIME(detectSkeleton3d)
    dgc_ret = bef_effect_ai_3d_skeleton_detect(_dgc_3dhandle, &_dgc_skeleton3dArgs, &_dgc_skeleton3dRet);
    STOP_TIME(detectSkeleton3d)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_3d_skeleton_detect, dgc_ret, dgc_result)
    
    dgc_result.skeletonInfo = &_dgc_skeleton3dRet;
    _dgc_needDetect = _dgc_skeleton3dRet.tracking == 0;
    
    return dgc_result;
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_AVATAR_SKELETON_3D_TOB
    bef_effect_ai_3d_skeleton_release(_dgc_3dhandle);
    bef_effect_ai_skeleton_destroy(_dgc_2dhandle);
    if(_dgc_skeletonInfo) free(_dgc_skeletonInfo);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBE3DSkeletonAlgorithmTask.SKELETON3D;
}

@end
