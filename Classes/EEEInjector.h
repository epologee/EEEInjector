#import <Foundation/Foundation.h>
#import "EEEBlockChainMapping.h"
#import "EEEBackwardCompatibleMapping.h"

#define EEEObjectMappedToClass(className) (className *)([[EEEInjector currentInjector] objectForMappedClass:[className class] withIdentifier:nil])
#define EEEClassMappedToClass(className) ([[EEEInjector currentInjector] classForMappedClass:[className class] withIdentifier:nil])
#define EEEObjectMappedToProtocol(protocolName) (id <protocolName>)([[EEEInjector currentInjector] objectForMappedProtocol:@protocol(protocolName) withIdentifier:nil])
#define EEEClassMappedToProtocol(protocolName) ([[EEEInjector currentInjector] classForMappedProtocol:@protocol(protocolName) withIdentifier:nil])

#define injectClass eee_classWithInjector:[EEEInjector currentInjector]
#define injectObject eee_objectFromInjector:[EEEInjector currentInjector]
#define injectObjectNamed(name) eee_objectFromInjector:[EEEInjector currentInjector] withIdentifier:name

@interface EEEInjector : NSObject <EEEMappingParent>

@property(nonatomic, readonly) id <EEEClassBlockChainMappingStart> (^mapClass)(Class mappedClass);
@property(nonatomic, readonly) id <EEEClassBlockChainMappingStart> (^mapClassWithIdentifier)(Class mappedClass, NSString *identifier);
@property(nonatomic, readonly) id <EEEProtocolBlockChainMappingStart> (^mapProtocol)(Protocol *mappedProtocol);
@property(nonatomic, readonly) id <EEEProtocolBlockChainMappingStart> (^mapProtocolWithIdentifier)(Protocol *mappedProtocol, NSString *identifier);

+ (instancetype)defaultCurrentInjector;

+ (instancetype)setCurrentInjector:(EEEInjector *)injector force:(BOOL)force;

+ (instancetype)currentInjector;

- (id)objectForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier;

- (id)objectForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier;

- (Class)classForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier;

- (Class)classForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier;

@end

@interface NSObject (EEEInjector)

+ (Class)eee_classWithInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector withIdentifier:(NSString *)identifier;

@end

@interface EEEInjector (BackwardCompatibility)

/// Use `injector.mapClass(...)` instead
- (EEEBackwardCompatibleMapping *)mapClass:(Class)class DEPRECATED_ATTRIBUTE;

/// Use `injector.mapClass(...)` instead
- (EEEBackwardCompatibleMapping *)mapClass:(Class)class overwriteExisting:(__unused BOOL)overwriteExisting DEPRECATED_ATTRIBUTE;

/// Use `injector.mapClassWithIdentifier(..., ...)` instead
- (EEEBackwardCompatibleMapping *)mapClass:(Class)class withIdentifier:(NSString *)identifier overwriteExisting:(__unused BOOL)overwriteExisting DEPRECATED_ATTRIBUTE;

@end