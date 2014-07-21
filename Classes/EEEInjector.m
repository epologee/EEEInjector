#import "EEEInjector.h"
#import "EEEIntrospectProperty.h"
#import "EEEMapping.h"
#import "EEEBackwardCompatibleMapping.h"

@interface EEEInjector () <EEEMappingParent>

@property(nonatomic, strong) NSMutableDictionary *mappingsByKey;

@end

@interface NSString (EEEInjector)

+ (NSString *)keyForClass:(Class)class withIdentifier:(NSString *)identifier;

+ (NSString *)keyForProtocol:(Protocol *)proto withIdentifier:(NSString *)identifier;

@end

@implementation EEEInjector

static EEEInjector *_currentInjector;

+ (instancetype)defaultCurrentInjector
{
    return [self setCurrentInjector:[[self alloc] init] force:NO];
}

+ (instancetype)setCurrentInjector:(EEEInjector *)injector force:(BOOL)force
{
    @synchronized (self)
    {
        if (!force && injector)
        {
            NSAssert(_currentInjector == nil, @"Won't setup the shared injector if there already is one.");
        }

        _currentInjector = injector;
    }

    return _currentInjector;
}

+ (instancetype)currentInjector
{
    return _currentInjector;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _mappingsByKey = [NSMutableDictionary dictionary];

        NSString *key = [NSString keyForClass:[EEEInjector class] withIdentifier:nil];
        self[key] = [EEEMapping mapClass:[EEEInjector class] parent:nil ].toObject(self);
    }

    return self;
}

- (id <EEEClassBlockChainMappingStart> (^)(Class))mapClass
{
    return ^id <EEEClassBlockChainMappingStart>(Class mappedClass) {
        return self.mapClassWithIdentifier(mappedClass, nil);
    };
}

- (id <EEEClassBlockChainMappingStart> (^)(Class, NSString *))mapClassWithIdentifier
{
    return ^id <EEEClassBlockChainMappingStart>(Class mappedClass, NSString *identifier) {
        NSString *key = [NSString keyForClass:mappedClass withIdentifier:identifier];
        id <EEEClassBlockChainMappingStart> mapping = [EEEMapping mapClass:mappedClass parent:self];
        self[key] = mapping;
        return mapping;
    };
}

- (id <EEEProtocolBlockChainMappingStart> (^)(Protocol *))mapProtocol
{
    return ^id <EEEProtocolBlockChainMappingStart>(Protocol *mappedProtocol) {
        return self.mapProtocolWithIdentifier(mappedProtocol, nil);
    };
}

- (id <EEEProtocolBlockChainMappingStart> (^)(Protocol *, NSString *))mapProtocolWithIdentifier
{
    return ^id <EEEProtocolBlockChainMappingStart>(Protocol *mappedProtocol, NSString *identifier) {
        NSString *key = [NSString keyForProtocol:mappedProtocol withIdentifier:identifier];
        id <EEEProtocolBlockChainMappingStart> mapping = [EEEMapping mapProtocol:mappedProtocol parent:self];
        self[key] = mapping;
        return mapping;
    };
}

- (void)removeChildMapping:(EEEMapping *)mapping
{
    [self.mappingsByKey enumerateKeysAndObjectsUsingBlock:^(NSString *key, EEEMapping *existingMapping, BOOL *stop) {
        if (existingMapping == mapping)
        {
            [self.mappingsByKey removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

#pragma mark - Retrieving objects from mapped protocols and classes

- (id)objectForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    EEEMapping *mapping = [self findOrCreateMappingForClass:mappedClass withIdentifier:identifier];
    return [mapping targetObject];
}

- (id)objectForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier
{
    EEEMapping *mapping = [self findOrCreateMappingForProtocol:mappedProtocol withIdentifier:identifier];
    return [mapping targetObject];
}

- (Class)classForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    EEEMapping *mapping = [self findOrCreateMappingForClass:mappedClass withIdentifier:identifier];
    return [mapping targetClass];
}

- (Class)classForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier
{
    EEEMapping *mapping = [self findOrCreateMappingForProtocol:mappedProtocol withIdentifier:identifier];
    return [mapping targetClass];
}

- (EEEMapping *)findOrCreateMappingForClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    NSString *key = [NSString keyForClass:mappedClass withIdentifier:identifier];
    EEEMapping *mapping = self[key];

    if (!mapping)
    {
        key = [NSString keyForClass:mappedClass withIdentifier:nil];
        mapping = self[key];

        if (!mapping)
        {
            mapping = (id) [EEEMapping mapClass:mappedClass parent:self];
            self[key] = mapping;
        }
    }

    return mapping;
}

- (EEEMapping *)findOrCreateMappingForProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier
{
    NSString *key = [NSString keyForProtocol:mappedProtocol withIdentifier:identifier];
    EEEMapping *mapping = self[key];

    if (!mapping)
    {
        key = [NSString keyForProtocol:mappedProtocol withIdentifier:nil];
        mapping = self[key];
    }

    return mapping;
}

- (id)objectForKeyedSubscript:(id <NSCopying>)key
{
    return self.mappingsByKey[key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id <NSCopying>)key
{
    self.mappingsByKey[key] = obj;
}

@end

@implementation NSObject (EEEInjector)

+ (Class)eee_classWithInjector:(EEEInjector *)injector
{
    NSAssert(injector, @"Can't inject from nil injector.");
    return [injector classForMappedClass:self withIdentifier:nil];
}

+ (id)eee_allocWithInjector:(EEEInjector *)injector
{
    NSAssert(injector, @"Can't inject from nil injector.");
    Class targetClass = [injector classForMappedClass:self withIdentifier:nil];
    return [targetClass alloc];
}

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector
{
    NSAssert(injector, @"Can't inject from nil injector.");
    return [self eee_objectFromInjector:injector withIdentifier:nil];
}

+ (instancetype)eee_objectFromInjector:(EEEInjector *)injector withIdentifier:(NSString *)identifier
{
    NSAssert(injector, @"Can't inject from nil injector.");
    id value = [injector objectForMappedClass:self withIdentifier:identifier];
    NSAssert(value != nil, @"No value found mapped to %@. Use allowImplicitMapping to prevent this from happening", [self class]);
    return value;
}

@end

@implementation NSString (EEEInjector)

+ (NSString *)keyForClass:(Class)class withIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@xC@%@", NSStringFromClass(class), identifier ? identifier : @""];
}

+ (NSString *)keyForProtocol:(Protocol *)proto withIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@xP@%@", NSStringFromProtocol(proto), identifier ? identifier : @""];
}

@end

@implementation EEEInjector (BackwardCompatibility)

- (EEEBackwardCompatibleMapping *)mapClass:(Class)class
{
    return [self mapClass:class overwriteExisting:YES];
}

- (EEEBackwardCompatibleMapping *)mapClass:(Class)class overwriteExisting:(BOOL)overwriteExisting
{
    return [self mapClass:class withIdentifier:nil overwriteExisting:overwriteExisting];
}

- (EEEBackwardCompatibleMapping *)mapClass:(Class)class withIdentifier:(NSString *)identifier overwriteExisting:(__unused BOOL)overwriteExisting
{
    return [[EEEBackwardCompatibleMapping alloc] initWithMapping:self.mapClassWithIdentifier(class, identifier)];
}

@end