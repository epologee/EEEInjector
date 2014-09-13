#import "TSTLazyInjectionCustom.h"
#import "NSObject+EEELazyInjection.h"

@implementation TSTLazyInjectionCustom

@dynamic stringPropertyWithCustomAccessor;

+ (void)initialize
{
    [self eee_setupLazyInjectionForDynamicProperties];
}

- (NSString *)stringPropertyWithCustomAccessor
{
    return @"Something";
}

@end
