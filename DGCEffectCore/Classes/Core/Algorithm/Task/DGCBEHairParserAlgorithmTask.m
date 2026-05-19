//  DGCBEHairParserAlgorithmTask.m
// EffectsARSDK


#import "DGCBEHairParserAlgorithmTask.h"
#import "DGCBEAlgorithmTaskFactory.h"
#import "bef_effect_ai_hairparser.h"

static int WIDTH = 128;
static int HEIGHT = 224;

@implementation DGCBEHairParserAlgorithmResult

@end
@interface DGCBEHairParserAlgorithmTask () {
    bef_effect_handle_t             _dgc_handle;
    int                             _dgc_size[3];
    unsigned char                   *_dgc_hairParserInfo;
    int                             _dgc_hairParserInfoLen;
}

@property (nonatomic, strong) id<BEHairParserResourceProvider> provider;

@end

@implementation DGCBEHairParserAlgorithmTask

@dynamic provider;

+ (DGCBEAlgorithmKey *)HAIR_PARSER {
    GET_TASK_KEY(hairParser, YES)
}

- (int)initTask {
#if BEF_HAIR_PARSE_TOB
    bef_effect_result_t dgc_ret = bef_effect_ai_hairparser_create(&_dgc_handle);
    CHECK_RET_AND_RETURN(bef_effect_ai_hairparser_create, dgc_ret)
    if (self.licenseProvider.licenseMode == OFFLINE_LICENSE) {
        dgc_ret = bef_effect_ai_hairparser_check_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HAIR_PARSE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_hairparser_check_license, dgc_ret)
    }
    else if (self.licenseProvider.licenseMode == ONLINE_LICENSE){
        if (![self.licenseProvider checkLicenseResult: @"getLicensePath"])
            return self.licenseProvider.errorCode;
        
        dgc_ret = bef_effect_ai_hairparser_check_online_license(_dgc_handle, [self.licenseProvider licensePath:BEF_HAIR_PARSE]);
        CHECK_RET_AND_RETURN(bef_effect_ai_hairparser_check_online_license, dgc_ret)
    }
    
    dgc_ret = bef_effect_ai_hairparser_init_model(_dgc_handle, self.provider.hairParserModelPath);
    CHECK_RET_AND_RETURN(bef_effect_ai_hairparser_init_model, dgc_ret)
    dgc_ret = bef_effect_ai_hairparser_set_param(_dgc_handle, WIDTH, HEIGHT, true, true);
    CHECK_RET_AND_RETURN(bef_effect_ai_hairparser_set_param, dgc_ret)
    return dgc_ret;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (id)process:(const unsigned char *)buffer width:(int)width height:(int)height stride:(int)stride format:(bef_ai_pixel_format)format rotation:(bef_ai_rotate_type)rotation {
#if BEF_HAIR_PARSE_TOB
    DGCBEHairParserAlgorithmResult *dgc_result = [DGCBEHairParserAlgorithmResult new];
    bef_effect_result_t dgc_ret = bef_effect_ai_hairparser_get_output_shape(_dgc_handle, _dgc_size, _dgc_size + 1, _dgc_size + 2);
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_hairparser_get_output_shape, dgc_ret, dgc_result)
    if (_dgc_hairParserInfoLen != _dgc_size[0] * _dgc_size[1] * _dgc_size[2]) {
        if (_dgc_hairParserInfo != nil) {
            free(_dgc_hairParserInfo);
        }
        _dgc_hairParserInfoLen = _dgc_size[0] * _dgc_size[1] * _dgc_size[2];
        _dgc_hairParserInfo = malloc(_dgc_hairParserInfoLen);
    }
    RECORD_TIME(parseHair)
    dgc_ret = bef_effect_ai_hairparser_do_detect(_dgc_handle, buffer, format, width, height, stride, rotation, _dgc_hairParserInfo, false);
    STOP_TIME(parseHair)
    CHECK_RET_AND_RETURN_RESULT(bef_effect_ai_hairparser_do_detect, dgc_ret, dgc_result)
    dgc_result.mask = _dgc_hairParserInfo;
    dgc_result.size = _dgc_size;
    return dgc_result;
    
#endif
    return nil;
}

- (int)destroyTask {
#if BEF_HAIR_PARSE_TOB
    bef_effect_ai_hairparser_destroy(_dgc_handle);
    free(_dgc_hairParserInfo);
    return 0;
    
#endif
    return BEF_RESULT_INVALID_INTERFACE;
}

- (DGCBEAlgorithmKey *)key {
    return DGCBEHairParserAlgorithmTask.HAIR_PARSER;
}

@end
