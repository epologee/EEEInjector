#import "TSTNonConformingObject.h"
#import "NSObject+EEELazyInjection.h"

@implementation TSTNonConformingObject

@dynamic mappableConformingObject;

+ (void)initialize
{
    [self eee_setupLazyInjectionForDynamicProperties];
}

@end