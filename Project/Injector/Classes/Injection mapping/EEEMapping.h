#import <Foundation/Foundation.h>
#import "EEEBlockChainMappingObject.h"

@interface EEEMapping : NSObject <EEEMappingParent>

@property(nonatomic, strong, readonly) Class targetClass;
@property(nonatomic, strong, readonly) id targetObject;
@property(nonatomic, strong, readonly) NSMutableDictionary *injectables;

@end