//  BEAlgorithmTaskKey.m
// EffectsARSDK


#import "DGCBEAlgorithmKey.h"

@interface DGCBEAlgorithmKey ()

@end

@implementation DGCBEAlgorithmKey

+ (instancetype)create:(NSString *)key {
    return [self create:key isTask:NO];
}

+ (instancetype)create:(NSString *)key isTask:(BOOL)isTask {
    DGCBEAlgorithmKey *obj = [[self alloc] init];
    obj.algorithmKey = key;
    obj.isTask = isTask;
    return obj;
}


- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[DGCBEAlgorithmKey class]]) {
        return NO;
    } else {
        return [self.algorithmKey isEqualToString:[(DGCBEAlgorithmKey *)other algorithmKey]];
    }
}

- (NSUInteger)hash
{
    return [self.algorithmKey hash];
}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    DGCBEAlgorithmKey * copy = [[[self class] alloc] init];
    copy.algorithmKey = self.algorithmKey;
    copy.isTask = self.isTask;
    return copy;
}

@end
