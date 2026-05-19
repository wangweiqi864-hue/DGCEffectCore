//  DGCBEHeadSegmentAlgorithmTask.m
// EffectsARSDK


#import "DGCBEHeadSegmentAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"

static int INPUT_WIDTH = 128;
static int INPUT_HEIGHT = 128;
static float ENABLE_TRACKING = 1;
static float MAX_FACE = 2;

@implementation DGCBEHeadSegmentAlgorithmResult

@end
@interface DGCBEHeadSegmentAlgorithmTask () {
    bef_ai_headseg_handle               _dgc_handle;
    bef_ai_headseg_output               _dgc_headSegInfo;
    DGCBEFaceAlgorithmTask                 *_dgc_faceTask;
}

@property (nonatomic, strong) id<BEHeadSegmentResourceProvider> provider;

@end

@implementation DGCBEHeadSegmentAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)HEAD_SEGMENT {
    GET_TASK_KEY(headSeg, YES)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>)licenseProvider{
    if (self = [super initWithProvider:provider licenseProvider:licenseProvider]) {
        _dgc_faceTask = [[DGCBEFaceAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
    }
    return self;
}

- (int)initTask {
#if BEF_HEAD_SEG_TOB
    bef_ai_headseg_config dgc_conf;
    dgc_conf.net_input_height = INPUT_HEIGHT;
    dgc_conf.net_input_width = INPUT_WIDTH;
    
    bef_effect_result_t dgc_ret = BEF_AI_HSeg_CreateHandler(&_dgc_handle);
    CHECK_RET_AND_RETURN(BEF_AI_HSeg_CreateHandler, dgc_ret)

    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = BEF_AI_HSeg_CheckLicense(_dgc_handle, [self.licenseProvider licensePath:BEF_HEAD_SEG]);
        CHECK_RET_AND_RETURN(BEF_AI_HSeg_CheckLicense, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = BEF_AI_HSeg_CheckOnlineLicense(_dgc_handle, [self.licenseProvider licensePath:BEF_HEAD_SEG]);
        CHECK_RET_AND_RETURN(BEF_AI_HSeg_CheckOnlineLicense, dgc_ret)
    }
    
    dgc_ret = BEF_AI_HSeg_SetConfig(_dgc_handle, &dgc_conf);
    CHECK_RET_AND_RETURN(BEF_AI_HSeg_SetConfig, dgc_ret)
    dgc_ret = BEF_AI_HSeg_SetParam(_dgc_handle, BEF_AI_HS_ENABLE_TRACKING, ENABLE_TRACKING);
    CHECK_RET_AND_RETURN(BEF_AI_HSeg_SetParam, dgc_ret)
    dgc_ret = BEF_AI_HSeg_SetParam(_dgc_handle, BEF_AI_HS_MAX_FACE, MAX_FACE);
    CHECK_RET_AND_RETURN(BEF_AI_HSeg_SetParam, dgc_ret)
    dgc_ret = BEF_AI_HSeg_InitModel(_dgc_handle, self.provider.headSegmentModelPath);
    CHECK_RET_AND_RETURN(BEF_AI_HSeg_InitModel, dgc_ret)
    dgc_ret = [_dgc_faceTask initTask];
    return dgc_ret;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)dgc_buffer width:(int)dgc_width height:(int)dgc_height stride:(int)dgc_stride format:(bef_ai_pixel_format)dgc_format rotation:(bef_ai_rotate_type)dgc_rotation {
#if BEF_HEAD_SEG_TOB

    DGCBEHeadSegmentAlgorithmResult *dgc_result = [DGCBEHeadSegmentAlgorithmResult new];
    
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:dgc_buffer width:dgc_width height:dgc_height stride:dgc_stride format:dgc_format rotation:dgc_rotation];
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    
    if (dgc_faceInfo == nil || dgc_faceInfo->face_count <= 0) return dgc_result;
    memset(&_dgc_headSegInfo, 0, sizeof(bef_ai_headseg_output));
    bef_ai_headseg_input dgc_args;
    dgc_args.image = dgc_buffer;
    dgc_args.image_width = dgc_width;
    dgc_args.image_height = dgc_height;
    dgc_args.image_stride = dgc_stride;
    dgc_args.orient = dgc_rotation;
    dgc_args.pixel_format = dgc_format;
    dgc_args.face_count = dgc_faceInfo->face_count;
    
    bef_ai_headseg_faceinfo dgc_headFaceInfo[dgc_args.face_count];
    for (int i = 0; i < dgc_args.face_count; i++) {
        dgc_headFaceInfo[i].face_id = dgc_faceInfo->base_infos[i].ID;
        memcpy(dgc_headFaceInfo[i].points, dgc_faceInfo->base_infos[i].points_array, sizeof(float) * 2 * 106);
    }
    dgc_args.face_info = dgc_headFaceInfo;
    
    RECORD_TIME(headSegment)
    bef_effect_result_t dgc_ret = BEF_AI_HSeg_DoHeadSeg(_dgc_handle, &dgc_args, &_dgc_headSegInfo);
    STOP_TIME(headSegment)
    CHECK_RET_AND_RETURN_RESULT(BEF_AI_HSeg_DoHeadSeg, dgc_ret, dgc_result);
    dgc_result.headSegInfo = &_dgc_headSegInfo;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_HEAD_SEG_TOB
    [_dgc_faceTask destroyTask];
    BEF_AI_HSeg_ReleaseHandle(_dgc_handle);
    return 0;
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEHeadSegmentAlgorithmTask.HEAD_SEGMENT;
}

@end
