//  BEAlgorithmTaskKey.h
// EffectsARSDK


#ifndef BEAlgorithmKey_h
#define BEAlgorithmKey_h

#import <Foundation/Foundation.h>

@interface DGCBEAlgorithmKey : NSObject<NSCopying>

+ (instancetype)create:(NSString *)key;
+ (instancetype)create:(NSString *)key isTask:(BOOL)isTask;

@property (nonatomic, copy) NSString *algorithmKey;
@property (nonatomic) BOOL isTask;

@end

//if (IS_TASK) {\
//    [DGCBEAlgorithmTaskFactory registerTask:key generator:^DGCBEAlgorithmTask *(id<BEAlgorithmResourceProvider> provider) {\
//        return [[self alloc] initWithProvider:provider];\
//    }];\
//}

#define GET_TASK_KEY(NAME, IS_TASK)\
    static dispatch_once_t onceToken;\
    static DGCBEAlgorithmKey *key;\
    dispatch_once(&onceToken, ^{\
        key = [DGCBEAlgorithmKey create:[NSString stringWithCString:(#NAME) encoding:NSUTF8StringEncoding]];\
        key.isTask = IS_TASK;\
    });\
    return key;

#endif /* BEAlgorithmKey_h */
