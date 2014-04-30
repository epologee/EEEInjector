#import <Foundation/Foundation.h>

@protocol EEEClassBlockChainMappingStart;

@interface EEEBackwardCompatibleMapping : NSObject

- (id)initWithMapping:(id <EEEClassBlockChainMappingStart>)mapping;

- (EEEBackwardCompatibleMapping *)toSubclass:(Class)subclass;

- (instancetype)toObject:(id)object;

- (instancetype)toBlock:(id (^)())block;

- (void)asSingleton;

- (void)singleServing;

/**
 There is no equivalent for this method in the Injector anymore.
 Try mapping a subclass with an identifier instead.
 */
- (void)allocOnly UNAVAILABLE_ATTRIBUTE;

@end