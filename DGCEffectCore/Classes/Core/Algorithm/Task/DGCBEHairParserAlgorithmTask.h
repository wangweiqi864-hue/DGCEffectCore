//  DGCBEHairParserAlgorithmTask.h
// EffectsARSDK


#import "DGCBEAlgorithmTask.h"

@protocol BEHairParserResourceProvider <BEAlgorithmResourceProvider>

- (const char *)hairParserModelPath;

@end

@interface DGCBEHairParserAlgorithmResult : NSObject

@property (nonatomic, assign) unsigned char *mask;
@property (nonatomic, assign) int *size;

@end

@interface DGCBEHairParserAlgorithmTask : DGCBEAlgorithmTask

+ (DGCBEAlgorithmKey *)HAIR_PARSER;

@end
