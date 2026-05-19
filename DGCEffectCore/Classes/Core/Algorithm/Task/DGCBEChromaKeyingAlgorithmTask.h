//  DGCBEDynamicGestureAlgorithmTask.h
//  BECore


#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_chroma_keying.h"

@protocol BEChromaKeyingResourceProvider <BEAlgorithmResourceProvider>
- (const char *)chromaKeyingModelPath;
@end

@interface DGCBEChromaKeyingAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_chroma_keying_ret *chromaKeyingInfo;

@end

@interface DGCBEChromaKeyingAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)CHROMA_KEYING;
+ (DGCBEAlgorithmKey *)CHROMA_KEYING_SOFT;

@end
