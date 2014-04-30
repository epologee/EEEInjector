#import <Foundation/Foundation.h>
#import "EEEBlockChainMapping.h"

@interface EEEMapping : NSObject

@property(nonatomic, strong, readonly) Class targetClass;
@property(nonatomic, strong, readonly) id targetObject;

+ (id <EEEClassBlockChainMappingStart>)mapClass:(Class)mappedClass parent:(id <EEEMappingParent>)parent;

+ (id <EEEProtocolBlockChainMappingStart>)mapProtocol:(Protocol *)mappedProtocol parent:(id <EEEMappingParent>)parent;

@end