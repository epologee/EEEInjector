#import "TSTLazyInjectionBase.h"
#import "NSObject+EEELazyInjection.h"

@implementation TSTLazyInjectionBase
{
    int _counter;
}

@dynamic stringPropertyInBaseClass;

+ (void)initialize
{
    [self eee_setupLazyInjectionForDynamicProperties];
}

- (id)init
{
    self = [super init];

    if (self)
    {
        static int counter = 0;
        _counter = ++counter;
    }

    return self;
}

- (NSString *)description
{
    NSMutableString *description = [NSMutableString stringWithFormat:@"<%@:", NSStringFromClass([self class])];

    [description appendFormat:@" instance=%i", _counter];
    [description appendString:@">"];
    return description;
}

@end