#import "EEEAbstractClassCluster.h"
#import "EEEInjector.h"

@implementation EEEAbstractClassCluster

+ (id)alloc
{
    EEEInjector *injector = [EEEInjector currentInjector];
    Class targetClass = [injector classForMappedClass:self withIdentifier:nil allowImplicit:NO];
    if (targetClass && ![self isEqual:targetClass])
    {
        return [targetClass alloc];
    }
    else
    {
        return [super alloc];
    }
}

+ (id)allocWithZone:(struct _NSZone *)zone
{
    EEEInjector *injector = [EEEInjector currentInjector];
    Class targetClass = [injector classForMappedClass:self withIdentifier:nil allowImplicit:NO];
    if (targetClass && ![self isEqual:targetClass])
    {
        return [targetClass allocWithZone:zone];
    }
    else
    {
        return [super allocWithZone:zone];
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    id object = [[self class] allocWithZone:zone];
    return object;
}

- (BOOL)isNotEqual:(id)other
{
    if (!other)
        return YES;

    if (other == self)
        return NO;

    if (![[other class] isEqual:[self class]])
        return YES;

    return NO;
}

@end