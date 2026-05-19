//  DGCBEAlgorithmResourceHelper.h
//  Algorithm


#ifndef BEAlgorithmResourceHelper_h
#define BEAlgorithmResourceHelper_h

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
#import "DGCBEObjectTrackingAlgorithmTask.h"

@interface DGCBEAlgorithmResourceHelper : NSObject <BEFaceResourceProvider, BEHandResourceProvider, BESkeletonResourceProvider, BE3DSkeletonResourceProvider, BEPetFaceResourceProvider, BEHeadSegmentResourceProvider, BEPortraitMattingResourceProvider, BESaliencyMattingResourceProvider, BEHairParserResourceProvider, BESkyResourceProvider, BELightClsResourceProvider, BEHumanDistanceResourceProvider, BEConcentrationResourceProvider, BEGazeEstimationResourceProvider, BEC1ResourceProvider, BEC2ResourceProvider, BEVideoClsResourceProvider, BECarResourceProvider, BEFaceVerifyResourceProvider, BEFaceClusterResourceProvider, BEActionRecognitionResourceProvider, BEDynamicGestureResourceProvider, BESkinSegmentationResourceProvider, BEBachSkeletonResourceProvider, BEChromaKeyingResourceProvider, BESlamResourceProvider, BEObjectTrackingResourceProvider>

@end

#endif /* BEAlgorithmResourceHelper_h */
