//  DGCBESlamAlgorithmTask.h
//  BECore


#ifndef BESlamAlgorithmTask_h
#define BESlamAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_slam.h"


@protocol BESlamResourceProvider <BEAlgorithmResourceProvider>

- (const char *)slamARModel;

@end

@interface DGCBESlamAlgorithmResult : NSObject

@property (nonatomic, assign) float *projectionMat;
@property (nonatomic, assign) float *cameraToWorldMatrixInverse;
@property (nonatomic, assign) float *modelMatrix;
@property (nonatomic, assign) float *gravityDirVec;

@property (nonatomic, assign) float pointsNum;
@property (nonatomic, assign) float *featurePoints; // [x1, y1, x2, y2, ...]

@property (nonatomic, assign) BOOL worldCoordDis;
@property (nonatomic, assign) BOOL featurePointsDis;

@end

@interface DGCBESlamAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)PLANE_TRACK;
+ (DGCBEAlgorithmKey *)WORLD_COORD;
+ (DGCBEAlgorithmKey *)FEATURE_POINTS;
+ (DGCBEAlgorithmKey *)REGION_TRACK;

- (void)setTimeStamp:(double)timestamp;
- (NSString *)getStatus;
- (void)processTouchEventX:(float)x Y:(float)y displayWidth:(NSUInteger)disWidth displayHeight:(NSUInteger)disHeight;

@end


#endif /* BESlamAlgorithmTask_h */
