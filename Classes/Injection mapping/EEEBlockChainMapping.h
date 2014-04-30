#import <Foundation/Foundation.h>

@protocol EEEBlockChainMappingStart, EEEBlockChainMapping, EEEBlockChainMappingEnd;
@class EEEMapping;

typedef enum
{
    EEEBlockChainOptionNone = 0,
    EEEBlockChainOptionRemoveAfterUse = 1 << 0,
    EEEBlockChainOptionKeepReference = 1 << 1,
    EEEBlockChainOptionAll = EEEBlockChainOptionRemoveAfterUse | EEEBlockChainOptionKeepReference
} EEEBlockChainOption;

#pragma - Block chain mapping API

@protocol EEEClassBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMapping> (^toSubclass)(Class subclass);

@end

@protocol EEEProtocolBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMapping> (^toConformingClass)(Class conformingClass);

@end

@protocol EEEBlockChainMappingStart <EEEBlockChainMapping>

@property(nonatomic, readonly) id <EEEBlockChainMappingEnd> (^toObject)(id object);

typedef id (^EEEInjectionBlock)();

@property(nonatomic, readonly) id <EEEBlockChainMapping> (^toBlock)(EEEInjectionBlock block);

@end

@protocol EEEBlockChainMappingEnd

@property(nonatomic, readonly) void (^removeAfterUse)(BOOL enabled);

@end

@protocol EEEBlockChainMapping <EEEBlockChainMappingEnd>

@property(nonatomic, readonly) void (^keepReference)(BOOL enabled);

@end

@protocol EEEMappingParent <NSObject>

- (void)removeChildMapping:(EEEMapping *)mapping;

@end
