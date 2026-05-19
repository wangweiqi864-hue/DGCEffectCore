//  DGCBEAvaBoostAlgorithmTask.h
//  Core


#ifndef BEAvaBoostAlgorithmTask_h
#define BEAvaBoostAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_avaboost.h"

@protocol BEAvaBoostResourceProvider <BEAlgorithmResourceProvider>

- (const char *)avaboostModel;

@end

@interface DGCBEAvaBoostAlgorithmResult : NSObject

@property (nonatomic, assign) bef_ai_avaboost_ret* avaboost_ret;

@end

@interface DGCBEAvaBoostAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)AVABOOST;

@end

#endif /* BEAvaBoostAlgorithmTask_h */
