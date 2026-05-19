//  DGCBEFaceFittingAlgorithmTask.h
//  Core


#ifndef BEFaceFittingAlgorithmTask_h
#define BEFaceFittingAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_facefitting.h"

@protocol BEFaceFittingResourceProvider <BEAlgorithmResourceProvider>

- (const char *)faceModel;
- (const char *)faceExtraModel;
- (const char *)faceFittingModel;

@end

@interface DGCBEFaceFittingAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_facefitting_result *facefitting_ret;

@end

@interface DGCBEFaceFittingAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)FACE_FITTING;


@end


#endif /* BEFaceFittingAlgorithmTask_h */
