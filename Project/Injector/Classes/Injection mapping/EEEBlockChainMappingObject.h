#import <Foundation/Foundation.h>

typedef enum
{
    EEEBlockChainOptionNone = 0,
    EEEBlockChainOptionRemoveAfterUse = 1 << 0,
    EEEBlockChainOptionKeepReference = 1 << 1,
    EEEBlockChainOptionAll = EEEBlockChainOptionRemoveAfterUse | EEEBlockChainOptionKeepReference
} EEEBlockChainOption;

@protocol EEEBlockChainMappingVoid

@end

@protocol EEEBlockChainMappingEnd

@property(nonatomic, readonly) id <EEEBlockChainMappingVoid> (^removeAfterUse)(BOOL enabled);

@end

@protocol EEEBlockChainMappingObject <EEEBlockChainMappingEnd>

@property(nonatomic, readonly) id <EEEBlockChainMappingVoid> (^keepReference)(BOOL enabled);

@end

@protocol EEEBlockChainMappingStart <EEEBlockChainMappingObject>

@property(nonatomic, readonly) id <EEEBlockChainMappingEnd> (^toObject)(id object);

typedef id (^EEEInjectionBlock)();

@property(nonatomic, readonly) id <EEEBlockChainMappingObject> (^toBlock)(EEEInjectionBlock block);

@end

@protocol EEEClassBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMappingObject> (^toSubclass)(Class subclass);

@end

@protocol EEEProtocolBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMappingObject> (^toConformingClass)(Class conformingClass);

@end

@class EEEMapping;

@protocol EEEMappingParent <NSObject>

+ (id <EEEClassBlockChainMappingStart>)mapClass:(Class)mappedClass;

+ (id <EEEProtocolBlockChainMappingStart>)mapProtocol:(Protocol *)mappedProtocol;

- (void)removeChildMapping:(EEEMapping *)mapping;

@end
