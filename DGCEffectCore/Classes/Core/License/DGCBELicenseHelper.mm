//  DGCBELicenseHelper.m
//  BECore


#import "DGCBELicenseHelper.h"
#import "bef_effect_ai_license_wrapper.h"
#import "BEHttpRequestProvider.h"
#import <vector>
#import <iostream>
#import "bef_effect_ai_api.h"
#import "bef_effect_ai_error_code_format.h"
#import "Core.h"

#define CHECK_LICENSE_RET(MSG, ret) \
if (ret != 0 && ret != -11 && ret != 1) {\
    const char *msg = bef_effect_ai_error_code_get(ret);\
    if (msg != NULL) {\
        NSLog(@"%s error: %d, %s", #MSG, ret, msg);\
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kBESdkErrorNotification"\
                                                    object:nil\
                                                userInfo:@{@"data": [NSString stringWithCString:msg encoding:NSUTF8StringEncoding]}];\
    } else {\
        NSLog(@"%s error: %d", #MSG, ret);\
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kBESdkErrorNotification"\
                                                    object:nil\
                                                    userInfo:@{@"data": [NSString stringWithFormat:@"%s error: %d", #MSG, ret]}];\
    }\
}

using namespace std;

static NSString *OFFLIN_LICENSE_PATH = @"LicenseBag";
static NSString *OFFLIN_BUNDLE = @"bundle";
static NSString *LICENSE_URL = @"https://cv.iccvlog.com/cv_tob/v1/api/sdk/tob_license/getlicense";
static NSString *KEY = @"cv_test_online1";
static NSString *SECRET = @"e479f002-4018-11eb-a1e0-b8599f494dc4";
static LICENSE_MODE_ENUM LICENSE_MODE = OFFLINE_LICENSE;
BOOL overSeasVersion = NO;

@interface DGCBELicenseHelper() {
    std::string         _dgc_licenseFilePath;
    LICENSE_MODE_ENUM   _dgc_licenseMode;
    EffectsSDK::LicenseProvider* _dgc_licenseProvider;
    EffectsSDK::HttpRequestProvider* _dgc_requestProvider;
}
@end

@implementation DGCBELicenseHelper

static DGCBELicenseHelper* _instance = nil;

+ (void)online_or_offline_model{
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([[def objectForKey:@"online_model_key"] isEqualToString:@"ONLINE_LICENSE"]) {
        LICENSE_MODE = ONLINE_LICENSE;
    }
    else if ([[def objectForKey:@"online_model_key"] isEqualToString:@"OFFLINE_LICENSE"]) {
        LICENSE_MODE = OFFLINE_LICENSE;
    }
    else {
        [def setObject:(LICENSE_MODE == ONLINE_LICENSE? @"ONLINE_LICENSE":@"OFFLINE_LICENSE") forKey:@"online_model_key"];
    }
    [def synchronize];
}
+(instancetype) shareInstance
{
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[super allocWithZone:NULL] init] ;
    }) ;
    
    return _instance ;
}

+(id) allocWithZone:(struct _NSZone *)zone
{
    return [DGCBELicenseHelper shareInstance] ;
}
 
-(id) copyWithZone:(struct _NSZone *)zone
{
    return [DGCBELicenseHelper shareInstance] ;
}

- (void)setParam:(NSString*)key value:(NSString*) value{
    if (_dgc_licenseProvider == nil)
        return;
    
    _dgc_licenseProvider->setParam([key UTF8String], [value UTF8String]);
}

- (id)init {
    self = [super init];
    if (self) {
        _errorCode = 0;
        _dgc_licenseMode = LICENSE_MODE;
        _dgc_licenseProvider = bef_effect_ai_get_license_wrapper_instance();
        if (_dgc_licenseMode == ONLINE_LICENSE)
        {
            _dgc_licenseProvider->setParam("mode", "ONLINE");
            _dgc_licenseProvider->setParam("url", [[self licenseUrl] UTF8String]);
            _dgc_licenseProvider->setParam("key", [[self licenseKey] UTF8String]);
            _dgc_licenseProvider->setParam("secret", [[self licenseSecret] UTF8String]);
            NSString *licenseName = [NSString stringWithFormat:@"/%s", "license.bag"];
            NSString *licensePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            licensePath = [licensePath stringByAppendingString:licenseName];
            _dgc_licenseProvider->setParam("licensePath", [licensePath UTF8String]);
        }
        else
        {
            _dgc_licenseProvider->setParam("mode", "OFFLINE");
            NSString *licenseName = [NSString stringWithFormat:@"/%s", LICENSE_NAME];
            NSString* licensePath = [[NSBundle mainBundle] pathForResource:OFFLIN_LICENSE_PATH ofType:OFFLIN_BUNDLE];
            licensePath = [licensePath stringByAppendingString:licenseName];
            _dgc_licenseProvider->setParam("licensePath", [licensePath UTF8String]);
        }

        _dgc_licenseFilePath = _dgc_licenseProvider->getParam("licensePath");
        _dgc_requestProvider = new BEHttpRequestProvider;
        _dgc_licenseProvider->registerHttpProvider(_dgc_requestProvider);
    }

    return self;
}

- (NSString *)licenseUrl {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([[def objectForKey:@"licenseUrl"] isEqual: @""] || [def objectForKey:@"licenseUrl"] == nil) {
        [def synchronize];
        return LICENSE_URL;
    }
    else {
        NSString *licenseUrl = [def objectForKey:@"licenseUrl"];
        [def synchronize];
        return licenseUrl;
    }
}

- (NSString *)licenseKey {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([[def objectForKey:@"licenseKey"] isEqual: @""] || [def objectForKey:@"licenseKey"] == nil) {
        [def synchronize];
        return KEY;
    }
    else {
        NSString *licenseKey = [def objectForKey:@"licenseKey"];
        [def synchronize];
        return licenseKey;
    }
}

- (NSString *)licenseSecret {
    NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
    if ([[def objectForKey:@"licenseSecret"] isEqual: @""] || [def objectForKey:@"licenseSecret"] == nil) {
        [def synchronize];
        
        return SECRET;
    }
    else {
        NSString *licenseSecret = [def objectForKey:@"licenseSecret"];
        [def synchronize];
        return licenseSecret;
    }
}

-(void)dealloc {
    delete _dgc_licenseProvider;
    delete _dgc_requestProvider;
}

- (const char *)licensePath: (bef_ai_license_function_type) type {
    int ret = 0;
    if([[NSFileManager defaultManager] fileExistsAtPath:[[NSString alloc] initWithCString:_dgc_licenseFilePath.c_str() encoding:NSUTF8StringEncoding]]){
        ret = bef_effect_ai_check_license_function(type, _dgc_licenseFilePath.c_str(), _dgc_licenseMode == ONLINE_LICENSE);
        if (ret == 0)
            return _dgc_licenseFilePath.c_str();
    }
    //not ONLINE_LICENSE does not need to be updated
    if (_dgc_licenseMode != ONLINE_LICENSE)
        return _dgc_licenseFilePath.c_str();

    if (strcmp(self.updateLicensePath, "") == 0)
        return "";

    ret = bef_effect_ai_check_license_function(type, _dgc_licenseFilePath.c_str(), _dgc_licenseMode == ONLINE_LICENSE);
    CHECK_LICENSE_RET(bef_effect_ai_check_license_function, ret)
    
    return _dgc_licenseFilePath.c_str();
}

- (const char *)licensePath {
    _errorCode = 0;
    _errorMsg = @"";
    std::map<std::string, std::string> params;
    _dgc_licenseProvider->getLicenseWithParams(params, false, [](const char* retmsg, int retSize, EffectsSDK::ErrorInfo error, void* userdata){
        DGCBELicenseHelper* pThis = CFBridgingRelease(userdata);
        pThis.errorCode = error.errorCode;
        pThis.errorMsg = [[NSString alloc] initWithCString:error.errorMsg.c_str() encoding:NSUTF8StringEncoding];
    }, (void*)CFBridgingRetain(self));

    if (![self checkLicenseResult: @"getLicensePath"])
        return "";

    _dgc_licenseFilePath = _dgc_licenseProvider->getParam("licensePath");
    return _dgc_licenseFilePath.c_str();
}

- (const char *)updateLicensePath {
    _errorCode = 0;
    _errorMsg = @"";
    std::map<std::string, std::string> params;
    _dgc_licenseProvider->updateLicenseWithParams(params, false, [](const char* retmsg, int retSize, EffectsSDK::ErrorInfo error, void* userdata){
        DGCBELicenseHelper* pThis = CFBridgingRelease(userdata);
        pThis.errorCode = error.errorCode;
        pThis.errorMsg = [[NSString alloc] initWithCString:error.errorMsg.c_str() encoding:NSUTF8StringEncoding];
    }, (void*)CFBridgingRetain(self));

    if (![self checkLicenseResult: @"updateLicensePath"])
        return "";
    
    _dgc_licenseFilePath = _dgc_licenseProvider->getParam("licensePath");
    return _dgc_licenseFilePath.c_str();
}

- (LICENSE_MODE_ENUM) licenseMode{
    return _dgc_licenseMode;
}

- (bool)checkLicenseResult:(NSString*) msg {
    if (_errorCode != 0) {
        if ([_errorMsg length] > 0) {
            NSLog(@"%a error: %d, %a", msg, _errorCode, _errorMsg);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kBESdkErrorNotification" object:nil
                                                      userInfo:@{@"data": _errorMsg}];
        } else {
            NSLog(@"%a error: %d", msg, _errorCode);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kBESdkErrorNotification" object:nil
                                                        userInfo:@{@"data": [NSString stringWithFormat:@"%a error: %d", msg, _errorCode]}];
        }
        return false;
    }
    return true;
}

- (bool)checkLicenseOK:(const char *) filePath {
    bef_effect_result_t ret = bef_effect_ai_check_license_function(BEF_EFFECT, _dgc_licenseFilePath.c_str(), _dgc_licenseMode == ONLINE_LICENSE);
    if (ret != 0 && ret != -11 && ret != 1)
    {
        return false;
    }
    
    return true;
}

- (bool)deleteCacheFile {
    std::string filePath = _dgc_licenseProvider->getParam("licensePath");
    if (!filePath.empty()) {
        NSString *path = [[NSString alloc] initWithUTF8String:filePath.c_str()];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL isDelete = [fileManager removeItemAtPath:path error:nil];
        if (!isDelete) {
            return false;
        }
    }
    
    return true;
}

@end
