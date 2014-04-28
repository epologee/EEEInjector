#import "TSTProtocolInjectionObject.h"
#import "NSObject+EEELazyInjection.h"

@implementation TSTProtocolInjectionObject

@dynamic conformingObject;

+ (void)initialize
{
    [self eee_setupLazyInjectionForDynamicProperties];
}

@end