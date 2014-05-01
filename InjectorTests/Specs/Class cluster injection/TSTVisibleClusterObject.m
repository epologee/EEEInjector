#import "TSTVisibleClusterObject.h"

@implementation TSTVisibleClusterObject

- (NSString *)whoAmI
{
    return @"an instance of the visible class cluster";
}

- (BOOL)isEqual:(id)other
{
    if ([self isNotEqual:other]) return NO;
    if (other == self) return YES;

    // default to yes
    return YES;
}

@end