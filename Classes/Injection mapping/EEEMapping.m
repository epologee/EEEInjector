#import "EEEMapping.h"

@interface EEEMapping () <EEEClassBlockChainMappingStart, EEEProtocolBlockChainMappingStart>

@property(nonatomic, strong) Class mappedClass;
@property(nonatomic, strong) EEEMapping *childMapping;
@property(nonatomic) EEEBlockChainTermination options;
@property(nonatomic, weak, readwrite) id <EEEMappingParent> parent;
@property(nonatomic, strong, readwrite) id targetObject;
@property(nonatomic, strong, readwrite) EEEInjectionBlock targetBlock;
@property(nonatomic, readonly) EEEMapping *endMapping;
@property(nonatomic, strong) NSMutableDictionary *injectables;
@property(nonatomic, strong) Protocol *mappedProtocol;

@end

@implementation EEEMapping

+ (id <EEEBlockChainMappingStart>)mapClass:(Class)mappedClass
{
    return [[self alloc] initWithMappedClass:mappedClass];
}

- (id)initWithMappedClass:(Class)mappedClass
{
    self = [super init];

    if (self)
    {
        self.mappedClass = mappedClass;
    }

    return self;
}

- (id <EEEBlockChainMappingEnd> (^)(id))toObject
{
    return ^id <EEEBlockChainMappingEnd>(id object) {
        self.targetObject = object;
        [self assertIntegrity];
        return self;
    };
}

- (id <EEEBlockChainMapping> (^)(UIImage *))andIcon
{
    return ^id <EEEBlockChainMapping>(UIImage *icon) {
        self.icon = icon;
        return self;
    };
}

- (id <EEEBlockChainMapping> (^)(void (^)(id)))andSelect
{
    return ^id <EEEBlockChainMapping>(void (^selectBlock)(id)) {
        self.selectBlock = selectBlock;
        return self;
    };
}
@end