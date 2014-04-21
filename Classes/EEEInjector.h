#import <Foundation/Foundation.h>
#import "EEEInjectionMapping.h"

#define injectClass eee_classWithInjector:[EEEInjector currentInjector]
#define injectAlloc eee_allocWithInjector:[EEEInjector currentInjector]
#define injectObject eee_objectFromInjector:[EEEInjector currentInjector]
#define injectObjectNamed(name) eee_objectFromInjector:[EEEInjector currentInjector] withIdentifier:name
#define inject eee_injectWithInjector:[EEEInjector currentInjector]

/**
 The EEEInjectable protocol is used to 'mark' properties to be injected automatically.
 The injected objects need not implement the protocol explicitly.
 You can, for example, inject an array property like this:
 @property (strong) NSArray <EEEInjectable>*plants;
 */
@protocol EEEInjectable <NSObject>

@optional
- (void)didInjectProperties;

@end

@class EEEInjector;

/**
 This mapper protocol is used to narrow down the methods you call on the injector directly.
 The rest of its methods are accessed through the NSObject category class methods below.
 Example:
 
 [[[self.injector mapClass:[CustomClass class]] toObject:[CustomSubclass]] singleServing];
 [[self.injector mapClass:[NSArray class] withIdentifier:@"plants"] toObject:@[@"Tree", @"Grass"]];
 */
@protocol EEEInjectionMapper

- (id <EEEInjectionMappingStart>)mapClass:(Class)class;

- (id <EEEInjectionMappingStart>)mapClass:(Class)class withIdentifier:(NSString *)identifier;

- (id <EEEInjectionMappingStart>)mapClass:(Class)class overwriteExisting:(BOOL)overwriteExisting;

- (id <EEEInjectionMappingStart>)mapClass:(Class)class withIdentifier:(NSString *)identifier overwriteExisting:(BOOL)overwriteExisting;

- (void)unmapClass:(Class)class;

- (void)unmapClass:(Class)class withIdentifier:(NSString *)identifier;

- (EEEInjector *)asInjector;

@end

/**
 The EEEInjector public interface only deals with class methods for setting and getting a/the shared injector.
 You can manually keep a reference to one or more injector instances if you prefer.
 */
@interface EEEInjector : NSObject <EEEInjectionMapper>

@property(nonatomic) BOOL allowImplicitMapping;

+ (instancetype)currentInjector;

+ (instancetype)defaultCurrentInjector;

+ (instancetype)setCurrentInjector:(EEEInjector *)injector force:(BOOL)force;

+ (EEEInjector *)sharedInjector DEPRECATED_ATTRIBUTE; // Replaced by currentInjector

+ (EEEInjector *)setSharedInjector DEPRECATED_ATTRIBUTE; // Replaced by defaultCurrentInjector

+ (EEEInjector *)setSharedInjector:(EEEInjector *)injector DEPRECATED_ATTRIBUTE; // Replaced by setCurrentInjector:force:

- (id <EEEInjectionMapper>)asMapper;

- (id)injectPropertiesIntoObject:(id)object;

@end

/**
 Retrieve mapped classes, objects or manually fire injection with these NSObject methods.
 Example:
 
    [[CustomClass eee_allocWithInjector:[EEEInjector sharedInjector]] initWithFrame:CGRectZero];
 
 There's a shorthand macro for this above, so you if you use the sharedInjector, you may write:
 
    [[CustomClass injectAlloc] initWithFrame:CGRectZero];
 
 Or try identifier-based mappings:
 
    [NSArray eee_objectFromInjector:[EEEInjector sharedInjector] withIdentifier:@"plants"];
 
 If objects are mapped with an identifier, properties that share that name will be automatically injected:
 
    @property (strong) NSArray <EEEInjectable>*plants;
 */
@interface NSObject (EEEInjector)

+ (Class)eee_classWithInjector:(EEEInjector *)injector;

+ (instancetype)eee_allocWithInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector withIdentifier:(NSString *)identifier;

- (instancetype)eee_injectWithInjector:(EEEInjector *)injector;

@end