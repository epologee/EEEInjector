#import "EEEMapping.h"

@interface EEEMapping () <EEEMappingParent>

@property(nonatomic, strong) Class mappedClass;
@property(nonatomic, strong) Protocol *mappedProtocol;
@property(nonatomic, weak, readwrite) id <EEEMappingParent> parent;
@property(nonatomic, strong) EEEMapping *childMapping;
@property(nonatomic) EEEBlockChainOption options;

@property(nonatomic, copy, readwrite) EEEInjectionBlock targetBlock;
@property(nonatomic, strong, readwrite) id targetObject;

@end

@interface EEEMapping (BlockChain) <EEEClassBlockChainMappingStart, EEEProtocolBlockChainMappingStart>
@end

@implementation EEEMapping

+ (id <EEEClassBlockChainMappingStart>)mapClass:(Class)mappedClass parent:(id <EEEMappingParent>)parent
{
    EEEMapping *mapping = [[self alloc] init];
    mapping.parent = parent;
    return [mapping mapClass:mappedClass];
}

+ (id <EEEProtocolBlockChainMappingStart>)mapProtocol:(Protocol *)mappedProtocol parent:(id <EEEMappingParent>)parent
{
    EEEMapping *mapping = [[self alloc] init];
    mapping.parent = parent;
    return [mapping mapProtocol:mappedProtocol];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        self.options = EEEBlockChainOptionNone;
    }

    return self;
}

- (id <EEEClassBlockChainMappingStart>)mapClass:(Class)mappedClass
{
    self.mappedClass = mappedClass;
    return self;
}

- (id <EEEProtocolBlockChainMappingStart>)mapProtocol:(Protocol *)mappedProtocol
{
    self.mappedProtocol = mappedProtocol;
    return self;
}

- (Class)targetClass
{
    if (self.childMapping != nil)
    {
        return [self.childMapping targetClass];
    }

    return self.mappedClass;
}

- (id)targetObject
{
    if (self.childMapping != nil)
    {
        return [self.childMapping targetObject];
    }

    id object = nil;

    if (_targetObject != nil)
    {
        object = _targetObject;
    }
    else if (_targetBlock != nil)
    {
        object = _targetBlock();
    }
    else if (self.mappedClass)
    {
        object = [[self.mappedClass alloc] init];
    }

    if (object)
    {
        if (self.options & EEEBlockChainOptionRemoveAfterUse)
        {
            [self removeFromParentMapping];
        }
        else if (self.options & EEEBlockChainOptionKeepReference)
        {
            _targetObject = object;
        }
    }

    return object;
}

#pragma mark - Removing parent mapping

- (void)removeChildMapping:(EEEMapping *)mapping
{
    // bubble up to the topmost parent, probably the injector.
    self.childMapping = nil;
    [self removeFromParentMapping];
}

- (void)removeFromParentMapping
{
    [self.parent removeChildMapping:self];
    self.parent = nil;
    [self didRemoveFromParentMapping];
}

- (void)didRemoveFromParentMapping
{
    self.targetObject = nil;
    self.targetBlock = nil;
    self.mappedClass = nil;
}

@end

@implementation EEEMapping (BlockChain)

- (id <EEEBlockChainMappingEnd> (^)(id))toObject
{
    NSParameterAssert(![_parent isKindOfClass:[self class]]);
    NSParameterAssert(_targetBlock == nil);
    return ^id <EEEBlockChainMappingEnd>(id object) {
        self.targetObject = object;
        return self;
    };
}

- (id <EEEBlockChainMapping> (^)(Class))toConformingClass
{
    return ^id <EEEBlockChainMapping>(Class conformingClass) {
        if (![conformingClass conformsToProtocol:self.mappedProtocol])
        {
            [[NSException exceptionWithName:@"EEEMapping"
                                     reason:@"Class does not conform to mapped protocol"
                                   userInfo:@{
                                           @"Class" : NSStringFromClass(conformingClass),
                                           @"Protocol" : NSStringFromProtocol(self.mappedProtocol)
                                   }] raise];
        }

        return self.toSubclass(conformingClass);
    };
}

- (id <EEEBlockChainMapping> (^)(Class))toSubclass
{
    NSParameterAssert(_targetObject == nil);
    NSParameterAssert(_targetBlock == nil);
    return ^id <EEEBlockChainMapping>(Class subclass) {
        EEEMapping *childMapping = [[EEEMapping alloc] init];
        childMapping.mappedClass = subclass;
        childMapping.parent = self;
        self.childMapping = childMapping;
        return self.childMapping;
    };
}

- (id <EEEBlockChainMapping> (^)(EEEInjectionBlock))toBlock
{
    NSParameterAssert(_targetObject == nil);
    NSParameterAssert(![_parent isKindOfClass:[self class]]);
    return ^id <EEEBlockChainMapping>(EEEInjectionBlock block) {
        self.targetBlock = block;
        return self;
    };
}

- (void (^)(BOOL))removeAfterUse
{
    return ^void(BOOL enable) {
        if (enable)
        {
            if (self.options & EEEBlockChainOptionKeepReference)
            {
                [[NSException exceptionWithName:@"EEEMapping"
                                         reason:@"Internal inconsistency, attempt to combine `removeAfterUse` with `keepReference`"
                                       userInfo:nil] raise];
            }

            self.options |= EEEBlockChainOptionRemoveAfterUse;
        }
        else
        {
            self.options ^= EEEBlockChainOptionRemoveAfterUse;
        }
    };
}

- (void (^)(BOOL))keepReference
{
    return ^void(BOOL enable) {
        if (enable)
        {
            if (self.options & EEEBlockChainOptionRemoveAfterUse)
            {
                [[NSException exceptionWithName:@"EEEMapping"
                                         reason:@"Internal inconsistency, attempt to combine `keepReference` with `removeAfterUse`"
                                       userInfo:nil] raise];
            }

            self.options |= EEEBlockChainOptionKeepReference;
        }
        else
        {
            self.options ^= EEEBlockChainOptionKeepReference;
        }
    };
}

@end