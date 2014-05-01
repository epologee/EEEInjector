#import "NSObject+EEEClassClusterInjection.h"

@implementation NSObject (EEEClassClusterInjection)

+ (id)alloc
{
    if ([self isEqual:[BNCTimer class]]) return [EEEClassMappedToClass(BNCTimer) alloc];
    else return [super alloc];
}

+ (id)allocWithZone:(NSZone *)zone
{
    if ([self isEqual:[BNCTimer class]]) return [EEEClassMappedToClass(BNCTimer) allocWithZone:zone];
    else return [super allocWithZone:zone];
}

- (id)copyWithZone:(NSZone *)zone
{
    BNCTimer *timer = [[self class] allocWithZone:zone];

    timer->_name = _name;
    timer->_duration = _duration;
    timer->_numberOfNotifications = _numberOfNotifications;
    timer->_notificationInterval = _notificationInterval;
    timer->_clearBadgeAfterCompletionInterval = _clearBadgeAfterCompletionInterval;

    return timer;
}

@end