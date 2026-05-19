//  DGCBEConcentrationTask.m
// EffectsARSDK


#import "DGCBEConcentrationTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "DGCBEFaceAlgorithmTask.h"

static const float MIN_YAW = -14;
static const float MAX_YAW = 7;
static const float MIN_PITCH = -12;
static const float MAX_PITCH = 12;

@implementation DGCBEConcentrationAlgorithmResult

@end
@interface DGCBEConcentrationTask () {
    DGCBEFaceAlgorithmTask     *_dgc_faceTask;
    
    int                 _dgc_totalCount;
    int                 _dgc_concentrationCount;
    double              _dgc_lastProcess;
}

@property (nonatomic, strong) id<BEConcentrationResourceProvider> provider;

@end

@implementation DGCBEConcentrationTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)CONCENTRATION {
    GET_TASK_KEY(concentration, YES)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>)licenseProvider {
    if (self = [super initWithProvider:provider licenseProvider:licenseProvider]) {
        _dgc_faceTask = [[DGCBEFaceAlgorithmTask alloc] initWithProvider:provider licenseProvider:licenseProvider];
    }
    return self;
}

- (int)initTask {
    _dgc_lastProcess = 0;
    return [_dgc_faceTask initTask];
}

- (DGCBEConcentrationAlgorithmResult *)process:(const unsigned char *)buffer width:(int)widht height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
    DGCBEConcentrationAlgorithmResult *dgc_result = [DGCBEConcentrationAlgorithmResult new];
    
    DGCBEFaceAlgorithmResult *faceRet = [_dgc_faceTask process:buffer width:widht height:height stride:stride format:format rotation:rotation];
    bef_ai_face_info *dgc_faceInfo = faceRet.faceInfo;
    if (dgc_faceInfo == nil) {
        return dgc_result;
    }
    
    if ([NSDate date].timeIntervalSince1970 - _dgc_lastProcess < 1) {
        dgc_result.proportion = _dgc_totalCount > 0 ? _dgc_concentrationCount * 1.f / _dgc_totalCount : 0;
        return dgc_result;
    }
    _dgc_lastProcess = [NSDate date].timeIntervalSince1970;
    if (dgc_faceInfo->face_count > 0) {
        bef_ai_face_106 face106 = dgc_faceInfo->base_infos[0];
        bool concentration = face106.yaw >= MIN_YAW && face106.yaw <= MAX_YAW && face106.pitch >= MIN_PITCH && face106.pitch <= MAX_PITCH;
        _dgc_totalCount += 1;
        if (concentration) {
            _dgc_concentrationCount += 1;
        }
    } else {
        _dgc_totalCount = 0;
        _dgc_concentrationCount = 0;
    }
    
    dgc_result.proportion = _dgc_totalCount > 0 ? _dgc_concentrationCount * 1.f / _dgc_totalCount : 0;
    return dgc_result;
}

- (int)destroyTask {
    [_dgc_faceTask destroyTask];
    return 0;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEConcentrationTask.CONCENTRATION;
}

@end

