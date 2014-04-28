#import <Foundation/Foundation.h>

@class EEEMapping;

typedef enum
{
    EEEBlockChainTerminationNone = 0,
    EEEBlockChainTerminationSingleServing = 1 << 0, // unmaps after calling `object` or `targetClass`.
    EEEBlockChainTerminationSingleton = 1 << 1, // alloc/init singleton. The opposite performs alloc/init every time.
    EEEBlockChainTerminationAllocOnly = 1 << 2 // `object` can't be called on a mapping like this.
} EEEBlockChainTermination;

typedef id (^EEEInjectionBlock)();

@protocol EEEBlockChainMappingEnd

- (void)singleServing;

@end

@protocol EEEBlockChainMapping <EEEBlockChainMappingEnd>

@property(nonatomic, readonly) id <EEEBlockChainMappingEnd> (^allocOnly);

- (void)asSingleton;

@end

@protocol EEEBlockChainMappingStart <EEEBlockChainMapping>

@property(nonatomic, readonly) id <EEEBlockChainMappingEnd> (^toObject)(id object);

@property(nonatomic, readonly) id <EEEBlockChainMappingEnd> (^toBlock)(EEEInjectionBlock block);

@end

@protocol EEEClassBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMapping> (^toSubclass)(Class subclass);

@end

@protocol EEEProtocolBlockChainMappingStart <EEEBlockChainMappingStart>

@property(nonatomic, readonly) id <EEEBlockChainMapping> (^toConformingClass)(Class conformingClass);

@end

@protocol EEEMappingParent <NSObject>

- (void)removeChildMapping:(EEEMapping *)mapping;

@end

@interface EEEMapping : NSObject

@property(nonatomic, strong, readonly) Class targetClass;
@property(nonatomic, strong, readonly) id targetObject;
@property(nonatomic, strong, readonly) NSMutableDictionary *injectables;

+ (id <EEEBlockChainMappingStart>)mapClass:(Class)mappedClass;

@end