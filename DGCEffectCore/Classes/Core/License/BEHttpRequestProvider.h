#ifndef BEHttpRequestProvider_h
#define BEHttpRequestProvider_h

#include "bef_effect_ai_license_wrapper.h"

class BEHttpRequestProvider: public EffectsSDK::HttpRequestProvider
{
    
public:
    bool getRequest(const EffectsSDK::RequestInfo* requestInfo, EffectsSDK::ResponseInfo& responseInfo) override;
    
    bool postRequest(const EffectsSDK::RequestInfo* requestInfo, EffectsSDK::ResponseInfo& responseInfo) override;
    
};
#endif //BEHttpRequestProvider_h
