//  BEAlgorithmManager.m
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"

@interface DGCBEAlgorithmTask () {
    id<BEAlgorithmResourceProvider> _dgc_provider;
    id<BELicenseProvider> _dgc_licenseProvider;
}

@property (nonatomic, strong) NSMutableDictionary<DGCBEAlgorithmKey *, NSObject *> *config;

@end

@implementation DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)ALGORITHM_FOV {
    GET_TASK_KEY(algorithmFov, NO)
}

- (instancetype)initWithProvider:(id<BEAlgorithmResourceProvider>)dgc_provider licenseProvider:(id<BELicenseProvider>) dgc_licenseProvider {
    self = [self init];
    if (self) {
        _dgc_provider = dgc_provider;
        _dgc_licenseProvider = dgc_licenseProvider;
        _config = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setConfig:(DGCBEAlgorithmKey *)key p:(NSObject *)dgc_p {
    self.config[key] = dgc_p;
}

- (BOOL)boolConfig:(DGCBEAlgorithmKey *)key orDefault:(BOOL)dgc_orDefault {
    if ([self.config.allKeys containsObject:key]) {
        return [(NSNumber *)self.config[key] boolValue];
    }
    return dgc_orDefault;
}

- (float)floatConfig:(DGCBEAlgorithmKey *)key orDefault:(float)dgc_orDefault {
    if ([self.config.allKeys containsObject:key]) {
        return [(NSNumber *)self.config[key] floatValue];
    }
    return dgc_orDefault;
}

@end
