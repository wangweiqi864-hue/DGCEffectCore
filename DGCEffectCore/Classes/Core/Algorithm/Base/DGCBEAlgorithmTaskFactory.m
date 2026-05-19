//  DGCBEAlgorithmTaskFactory.m
//  Core


#import "DGCBEAlgorithmTaskFactory.h"
#import "DGCBEFaceAlgorithmTask.h"
#import "DGCBEHandAlgorithmTask.h"
#import "DGCBESkeletonAlgorithmTask.h"
#import "DGCBE3DSkeletonAlgorithmTask.h"
#import "DGCBEPetFaceAlgorithmTask.h"
#import "DGCBEHeadSegmentAlgorithmTask.h"
#import "DGCBEPortraitMattingAlgorithmTask.h"
#import "DGCBESaliencyMattingAlgorithmTask.h"
#import "DGCBEHairParserAlgorithmTask.h"
#import "DGCBESkySegAlgorithmTask.h"
#import "DGCBELightClsAlgorithmTask.h"
#import "DGCBEHumanDistanceAlgorithmTask.h"
#import "DGCBEConcentrationTask.h"
#import "DGCBEGazeEstimationTask.h"
#import "DGCBEC1AlgorithmTask.h"
#import "DGCBEC2AlgorithmTask.h"
#import "DGCBEVideoClsAlgorithmTask.h"
#import "DGCBECarDetectTask.h"
#import "DGCBEFaceVerifyAlgorithmTask.h"
#import "DGCBEFaceClusterAlgorithmTask.h"
#import "DGCBEActionRecognitionAlgorithmTask.h"
#import "DGCBEDynamicGestureAlgorithmTask.h"
#import "DGCBESkinSegmentationAlgorithmTask.h"
#import "DGCBEBachSkeletonAlgorithmTask.h"
#import "DGCBEChromaKeyingAlgorithmTask.h"
#import "DGCBESlamAlgorithmTask.h"
#import "DGCBEFaceFittingAlgorithmTask.h"
#import "DGCBEAvaBoostAlgorithmTask.h"
#import "DGCBEObjectTrackingAlgorithmTask.h"

#define REGISTER_ALGORITHM_TASK(CLASS, KEY)\
[self register:CLASS.KEY generator:^DGCBEAlgorithmTask *(id<BEAlgorithmResourceProvider> provider, id<BELicenseProvider> licenseProvider) {\
return [[CLASS alloc] initWithProvider:provider licenseProvider:licenseProvider];\
}];

static NSMutableDictionary<DGCBEAlgorithmKey *, BEAlgorithmTaskGenerator> *dict;

@implementation DGCBEAlgorithmTaskFactory

+ (void)initialize
{
    if (self == [DGCBEAlgorithmTaskFactory class]) {
        dict = [NSMutableDictionary dictionary];
    }
    
    REGISTER_ALGORITHM_TASK(DGCBEFaceAlgorithmTask, FACE_106)
    REGISTER_ALGORITHM_TASK(DGCBEHandAlgorithmTask, HAND)
    REGISTER_ALGORITHM_TASK(DGCBESkeletonAlgorithmTask, SKELETON)
    REGISTER_ALGORITHM_TASK(DGCBE3DSkeletonAlgorithmTask, SKELETON3D)
    REGISTER_ALGORITHM_TASK(DGCBEPetFaceAlgorithmTask, PET_FACE)
    REGISTER_ALGORITHM_TASK(DGCBEHeadSegmentAlgorithmTask, HEAD_SEGMENT)
    REGISTER_ALGORITHM_TASK(DGCBEPortraitMattingAlgorithmTask, PORTRAIT_MATTING)
    REGISTER_ALGORITHM_TASK(DGCBESaliencyMattingAlgorithmTask, SALIENCY_MATTING)
    REGISTER_ALGORITHM_TASK(DGCBEHairParserAlgorithmTask, HAIR_PARSER)
    REGISTER_ALGORITHM_TASK(DGCBESkySegAlgorithmTask, SKY_SEG)
    REGISTER_ALGORITHM_TASK(DGCBELightClsAlgorithmTask, LIGHT_CLS)
    REGISTER_ALGORITHM_TASK(DGCBEHumanDistanceAlgorithmTask, HUMAN_DISTANCE)
    REGISTER_ALGORITHM_TASK(DGCBEConcentrationTask, CONCENTRATION)
    REGISTER_ALGORITHM_TASK(DGCBEGazeEstimationTask, GAZE_ESTIMATION)
    REGISTER_ALGORITHM_TASK(DGCBEC1AlgorithmTask, C1)
    REGISTER_ALGORITHM_TASK(DGCBEC2AlgorithmTask, C2)
    REGISTER_ALGORITHM_TASK(DGCBEVideoClsAlgorithmTask, VIDEO_CLS)
    REGISTER_ALGORITHM_TASK(DGCBECarDetectTask, CAR)
    REGISTER_ALGORITHM_TASK(DGCBEFaceVerifyAlgorithmTask, FACE_VERIFY)
    REGISTER_ALGORITHM_TASK(DGCBEFaceClusterAlgorithmTask, FACE_CLUSTER)
    REGISTER_ALGORITHM_TASK(DGCBEActionRecognitionAlgorithmTask, ACTION_RECOGNITION)
    REGISTER_ALGORITHM_TASK(DGCBEDynamicGestureAlgorithmTask, DYNAMIC_GESTURE)
    REGISTER_ALGORITHM_TASK(DGCBESkinSegmentationAlgorithmTask, SKIN_SEGMENTATION)
    REGISTER_ALGORITHM_TASK(DGCBEBachSkeletonAlgorithmTask, BACH_SKELETON)
    REGISTER_ALGORITHM_TASK(DGCBEChromaKeyingAlgorithmTask, CHROMA_KEYING)
    REGISTER_ALGORITHM_TASK(DGCBESlamAlgorithmTask, PLANE_TRACK)
    REGISTER_ALGORITHM_TASK(DGCBEFaceFittingAlgorithmTask, FACE_FITTING)
    REGISTER_ALGORITHM_TASK(DGCBEAvaBoostAlgorithmTask, AVABOOST)
    REGISTER_ALGORITHM_TASK(DGCBEObjectTrackingAlgorithmTask, OBJECT_TRACKING)
}

+ (DGCBEAlgorithmTask *)create:(DGCBEAlgorithmKey *)key provider:(id<BEAlgorithmResourceProvider>)provider licenseProvider:(id<BELicenseProvider>) licenseProvider {
    if ([dict.allKeys containsObject:key]) {
        return dict[key](provider, licenseProvider);
    }
    return nil;
}

+ (void)register:(DGCBEAlgorithmKey *)key generator:(BEAlgorithmTaskGenerator)generator {
    dict[key] = generator;
}

@end
