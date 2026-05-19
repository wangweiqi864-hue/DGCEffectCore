//  DGCBEFaceClusterAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceVerifyAlgorithmTask.h"
#import <UIKit/UIKit.h>

@protocol BEFaceClusterResourceProvider <BEFaceVerifyResourceProvider>

@end


@interface DGCBEFaceClusterAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)FACE_CLUSTER;

- (NSMutableDictionary<NSNumber *, NSMutableArray *> *)faceClusterImages:(NSArray<UIImage *> *)images;

@end
