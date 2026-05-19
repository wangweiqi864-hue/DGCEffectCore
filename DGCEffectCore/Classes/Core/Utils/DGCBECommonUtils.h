//  DGCBECommonUtils.h
//  BECore


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DGCBECommonUtils : NSObject

+ (UIColor *) colorWithHexString: (NSString *) hexString;

typedef NS_ENUM(NSInteger, BEDataType) {
    BEDataTypeInt,
    BEDataTypeFloat,
    BEDataTypeShort
};

// {zh} / 此处c++模板更好 {en} /Here c ++ template is better
+(void*) loadFileData:(NSString*) file dataLength:(int*) length dataType:(BEDataType) dataType ;

+(void*) loadBinaryFileData:(NSString*) file dataLength:(int*) length dataType:(BEDataType) dataType;

// {zh} / 图片到纹理 {en} /image to texture
+(GLuint) loadTextureFromFile:(NSString*) imagePath;
@end

NS_ASSUME_NONNULL_END
