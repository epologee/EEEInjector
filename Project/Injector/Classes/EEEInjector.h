#import <Foundation/Foundation.h>
#import "EEEBlockChainMapping.h"

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

@end

@interface NSObject (EEEInjector)

+ (Class)eee_classWithInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector;

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector withIdentifier:(NSString *)identifier;

@end