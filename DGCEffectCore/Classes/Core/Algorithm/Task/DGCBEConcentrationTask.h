//  DGCBEConcentrationTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"
#import "DGCBEFaceAlgorithmTask.h"

@protocol BEConcentrationResourceProvider <BEFaceResourceProvider>

@end

@interface DGCBEConcentrationAlgorithmResult : NSObject

@property (nonatomic, assign) float proportion;

@end

@interface DGCBEConcentrationTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)CONCENTRATION;

@end
