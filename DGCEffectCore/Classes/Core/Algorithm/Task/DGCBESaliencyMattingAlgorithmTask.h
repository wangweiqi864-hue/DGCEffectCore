//
//  DGCBESaliencyMattingAlgorithmTask.h
//  BECore
//
//  Created by ByteDance on 2023/04/23.
//

#ifndef BESaliencyMattingAlgorithmTask_h
#define BESaliencyMattingAlgorithmTask_h

#import "DGCBEAlgorithmTask.h"
#import "bef_effect_ai_saliency_matting.h"

@protocol BESaliencyMattingResourceProvider <BEAlgorithmResourceProvider>
- (const char *)saliencyMattingModelPath;
@end

@interface DGCBESaliencyMattingAlgorithmResult : NSObject

@property (nonatomic, assign) unsigned char *mask;
@property (nonatomic, assign) int *size;

@end

@interface DGCBESaliencyMattingAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)SALIENCY_MATTING;

@end

#endif /* BESaliencyMattingAlgorithmTask_h */
