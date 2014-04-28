#import "EEEInjector.h"
#import "EEEIntrospectProperty.h"

static EEEInjector *_currentInjector;

@interface EEEInjector () <EEEInjectionMappingParent, EEEInjectorInternals>

@property(nonatomic, strong) NSMutableDictionary *mappings;

@end

@implementation EEEInjector

+ (instancetype)currentInjector
{
    return _currentInjector;
}

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

+ (EEEInjector *)sharedInjector
{
    return [self currentInjector];
}

+ (EEEInjector *)setSharedInjector
{
    return [self setSharedInjector:[[self alloc] init]];
}

+ (EEEInjector *)setSharedInjector:(EEEInjector *)injector
{
    @synchronized (self)
    {
        if (injector)
        {
            NSAssert(_currentInjector == nil, @"Won't setup the shared injector if there already is one.");
        }

        _currentInjector = injector;
    }
    return _currentInjector;
}

+ (NSString *)keyForClass:(Class)class withIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@xC@%@", NSStringFromClass(class), identifier ? identifier : @""];
}

+ (NSString *)keyForProtocol:(Protocol *)proto withIdentifier:(NSString *)identifier
{
    return [NSString stringWithFormat:@"%@xP@%@", NSStringFromProtocol(proto), identifier ? identifier : @""];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self.mappings = [NSMutableDictionary dictionary];

        [[self mapClass:[self class]] toObject:self];
    }

    return self;
}

- (id <EEEInjectionMapper>)asMapper
{
    return self;
}

#pragma mark - Mapping protocols and classes

- (id <EEEClassInjectionMappingStart>)mapClass:(Class)class
{
    return [self mapClass:class withIdentifier:nil];
}

- (id <EEEClassInjectionMappingStart>)mapClass:(Class)class withIdentifier:(NSString *)identifier
{
    return [self mapClass:class withIdentifier:identifier overwriteExisting:YES];
}

- (id <EEEClassInjectionMappingStart>)mapClass:(Class)class overwriteExisting:(BOOL)overwriteExisting
{
    return [self mapClass:class withIdentifier:nil overwriteExisting:overwriteExisting];
}

- (id <EEEClassInjectionMappingStart>)mapClass:(Class)class withIdentifier:(NSString *)identifier overwriteExisting:(BOOL)overwriteExisting
{
    NSString *key = [[self class] keyForClass:class withIdentifier:identifier];

    if (!overwriteExisting)
    {
        NSAssert([self.mappings objectForKey:key] == nil, @"Attempted duplicate mapping for key %@", key);
    }

    EEEInjectionMapping *mapping = [[EEEInjectionMapping alloc] initWithParent:self mappedClass:class options:EEETerminationOptionNone];
    self.mappings[key] = mapping;

    return mapping;
}

- (void)unmapClass:(Class)class
{
    [self unmapClass:class withIdentifier:nil];
}

- (void)unmapClass:(Class)class withIdentifier:(NSString *)identifier
{
    NSString *key = [[self class] keyForClass:class withIdentifier:identifier];
    NSAssert([self.mappings objectForKey:key] != nil, @"Can't unmap a class if there's no such mapping (%@)", key);

    [self.mappings removeObjectForKey:key];
}

- (id <EEEProtocolInjectionMappingStart>)mapProtocol:(Protocol *)protocol
{
    return [self mapProtocol:protocol withIdentifier:nil overwriteExisting:YES];
}

- (id <EEEProtocolInjectionMappingStart>)mapProtocol:(Protocol *)protocol withIdentifier:(NSString *)identifier overwriteExisting:(BOOL)overwriteExisting
{
    NSString *key = [[self class] keyForProtocol:protocol withIdentifier:identifier];

    if (!overwriteExisting)
    {
        NSAssert([self.mappings objectForKey:key] == nil, @"Attempted duplicate mapping for key %@", key);
    }

    EEEInjectionMapping *mapping = [[EEEInjectionMapping alloc] initWithParent:self mappedProtocol:protocol options:EEETerminationOptionNone];
    self.mappings[key] = mapping;

    return mapping;
}

- (void)removeChildMapping:(EEEInjectionMapping *)mapping
{
    [self.mappings enumerateKeysAndObjectsUsingBlock:^(NSString *key, EEEInjectionMapping *existingMapping, BOOL *stop) {
        if (existingMapping == mapping)
        {
            [self.mappings removeObjectForKey:key];
            *stop = YES;
        }
    }];
}

- (EEEInjector *)asInjector
{
    return self;
}


#pragma mark - Retrieving objects from mapped protocols and classes



- (id)objectForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    EEEInjectionMapping *mapping = [self mappingForMappedClass:mappedClass withIdentifier:identifier];
    return [self injectPropertiesIntoObject:[mapping targetObject] withMapping:mapping];
}

- (id)objectForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier
{
    EEEInjectionMapping *mapping = [self mappingForMappedProtocol:mappedProtocol withIdentifier:identifier];
    return [self injectPropertiesIntoObject:[mapping targetObject] withMapping:mapping];
}

- (EEEInjectionMapping *)mappingForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    NSString *key = [[self class] keyForClass:mappedClass withIdentifier:identifier];
    EEEInjectionMapping *mapping = self.mappings[key];

    if (!mapping)
    {
        key = [[self class] keyForClass:mappedClass withIdentifier:nil];
        mapping = self.mappings[key];
    }

    if (!mapping && self.allowImplicitMapping)
    {
        mapping = [[EEEInjectionMapping alloc] initWithParent:self mappedClass:mappedClass options:EEETerminationOptionNone];
    }

    return mapping;
}

- (EEEInjectionMapping *)mappingForMappedProtocol:(Protocol *)mappedProtocol withIdentifier:(NSString *)identifier
{
    NSString *key = [[self class] keyForProtocol:mappedProtocol withIdentifier:identifier];
    EEEInjectionMapping *mapping = self.mappings[key];

    if (!mapping)
    {
        key = [[self class] keyForProtocol:mappedProtocol withIdentifier:nil];
        mapping = self.mappings[key];
    }

    if (!mapping && !self.allowImplicitMapping)
    {
        // TODO: Raise error for unmapped protocol?
    }

    return mapping;
}

- (Class)classForMappedClass:(Class)mappedClass withIdentifier:(NSString *)identifier
{
    EEEInjectionMapping *mapping = [self mappingForMappedClass:mappedClass withIdentifier:identifier];
    return [mapping targetClass];
}


#pragma mark - Property injection

- (id)injectPropertiesIntoObject:(id)object
{
    return [self injectPropertiesIntoObject:object withMapping:nil];
}

- (id)injectPropertiesIntoObject:(id)object withMapping:(EEEInjectionMapping *)mapping
{
    if (!mapping && self.allowImplicitMapping)
    {
        // Multiple injection calls on the same object-kind could cause multiple mappings
        // to be created implicitly, overwriting each other as values in the classMappings
        // dictionary. This @synchronized block prevents this to cause race conditions and
        // over-released mapping objects.
        @synchronized (self)
        {
            if (!mapping && self.allowImplicitMapping)
            {
                NSString *key = [[self class] keyForClass:[object class] withIdentifier:nil];
                mapping = [[EEEInjectionMapping alloc] initWithParent:self mappedClass:[object class] options:EEETerminationOptionNone];
                self.mappings[key] = mapping;
            }
        }
    }
    BOOL previouslyInjected = [self performInjectionOnObject:object withMapping:mapping];

    if (!previouslyInjected && [object respondsToSelector:@selector(didInjectProperties)])
    {
        [object didInjectProperties];
    }

    return object;
}

- (BOOL)performInjectionOnObject:(NSObject <EEEInjectable> *)object withMapping:(EEEInjectionMapping *)mapping
{
    __block int count = 0;
    __block BOOL nonNilPropertiesFound = NO;
    if (mapping)
    {
        [mapping.injectables enumerateKeysAndObjectsUsingBlock:^(NSString *identifier, id typeClass, BOOL *stop) {
            if ([object valueForKey:identifier] == nil)
            {
                count++;
                id value = [self objectForMappedClass:typeClass withIdentifier:identifier];
                [object setValue:value forKey:identifier];
            }
            else
            {
                nonNilPropertiesFound = YES;
            }
        }];
    }
    else
    {
        NSArray *properties = [EEEIntrospectProperty propertiesOfClass:[object class]];

        for (EEEIntrospectProperty *prop in properties)
        {
            if (prop.isObject && [prop implementsProtocol:@protocol(EEEInjectable)])
            {
                if ([object valueForKey:prop.name] == nil)
                {
                    count++;
                    id value = [self objectForMappedClass:prop.typeClass withIdentifier:prop.name];
                    if (!value) value = [self objectForMappedClass:prop.typeClass withIdentifier:nil];
                    NSAssert(value != nil, @"No mapping found for property %@ marked with <EEEInjectable>", prop.name);
                    [object setValue:value forKey:prop.name];
                }
                else
                {
                    nonNilPropertiesFound = YES;
                }
            }
        }
    }

    return nonNilPropertiesFound;
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

- (instancetype)eee_injectWithInjector:(EEEInjector *)injector
{
    NSAssert(injector, @"Can't inject from nil injector.");
    [injector injectPropertiesIntoObject:(id <EEEInjectable>) self withMapping:nil ];
    return self;
}

@end