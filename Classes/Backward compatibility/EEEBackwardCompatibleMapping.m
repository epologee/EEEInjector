#import "EEEBackwardCompatibleMapping.h"
#import "EEEBlockChainMapping.h"

@interface EEEBackwardCompatibleMapping ()

@property(nonatomic, strong) id <EEEClassBlockChainMappingStart, EEEProtocolBlockChainMappingStart> mapping;

@end

@implementation EEEBackwardCompatibleMapping

- (id)initWithMapping:(id <EEEClassBlockChainMappingStart>)mapping
{
    self = [super init];

    if (self)
    {
        self.mapping = (id) mapping;
    }

    return self;
}

- (instancetype)toSubclass:(Class)subclass
{
    self.mapping = (id) self.mapping.toSubclass(subclass);
    return self;
}

- (instancetype)toObject:(id)object
{
    self.mapping = (id) self.mapping.toObject(object);
    return self;
}

- (instancetype)toBlock:(id (^)())block
{
    self.mapping = (id) self.mapping.toBlock(block);
    return self;
}

- (void)asSingleton
{
    self.mapping.keepReference(YES);
}

- (void)singleServing
{
    self.mapping.removeAfterUse(YES);
}

- (void)allocOnly
{
    [self doesNotRecognizeSelector:_cmd];
}

@end