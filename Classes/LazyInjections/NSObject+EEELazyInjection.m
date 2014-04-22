#import <objc/runtime.h>
#import "NSObject+EEELazyInjection.h"
#import "EEEInjector.h"
#import "EEEIntrospectProperty.h"

NSString *EEEPropertyNameFromSetter(SEL setter) {
    NSString *selectorString = NSStringFromSelector(setter);
    if ([selectorString length] >= 5)
    {
        NSMutableString *propertyName = [NSMutableString string];
        [propertyName appendString:[[selectorString substringWithRange:NSMakeRange(3, 1)] lowercaseString]];
        [propertyName appendString:[selectorString substringWithRange:NSMakeRange(4, selectorString.length - 5)]];

        return propertyName;
    }
    else
    {
        [NSException raise:NSInvalidArgumentException format:@"The setter should include `set` and the colon `:`, thus a minimal length of 5 characters"];
        return nil;
    }
}

NSString *EEEPropertyNameFromGetter(SEL getter) {
    NSString *propertyName = NSStringFromSelector(getter);
    if ([propertyName rangeOfString:@":"].location != NSNotFound)
    {
        [[NSAssertionHandler currentHandler] handleFailureInFunction:@"EEEPropertyNameFromGetter"
                                                                file:[NSString stringWithUTF8String:__FILE__]
                                                          lineNumber:__LINE__
                                                         description:@"Invalid getter format, includes arguments: `%@`", propertyName];
    }

    return propertyName;
}

SEL EEESetterForPropertyName(NSString *propertyName) {
    NSMutableString *setter = [NSMutableString stringWithString:@"set"];
    [setter appendString:[[propertyName substringWithRange:NSMakeRange(0, 1)] uppercaseString]];
    [setter appendString:[propertyName substringWithRange:NSMakeRange(1, propertyName.length - 1)]];
    [setter appendString:@":"];
    return NSSelectorFromString(setter);
}

objc_AssociationPolicy EEEAssociationPolicyForProperty(objc_property_t property, char const *key) {

    NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray *pairs = [attributes componentsSeparatedByString:@","];

    __block BOOL nonatomic = NO;
    __block objc_AssociationPolicy association = OBJC_ASSOCIATION_ASSIGN;

    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSString *attribute = [pair substringToIndex:1];

        if ([@"N" isEqualToString:attribute])
        {
            nonatomic = YES;
        }
        else if ([@"C" isEqualToString:attribute])
        {
            // copy
            association = OBJC_ASSOCIATION_COPY;
        }
        else if ([@"&" isEqualToString:attribute])
        {
            // strong
            association = OBJC_ASSOCIATION_RETAIN;
        }
        else if ([@"W" isEqualToString:attribute])
        {
            // weak
            association = OBJC_ASSOCIATION_ASSIGN;
        }
    }];

    if (nonatomic)
    {
        switch (association)
        {
            default:
                break;
            case OBJC_ASSOCIATION_RETAIN:
                association = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
                break;
            case OBJC_ASSOCIATION_COPY:
                association = OBJC_ASSOCIATION_COPY_NONATOMIC;
                break;
        }
    }

    return association;
}

Class EEEClassForProperty(objc_property_t property, NSArray **protocols) {

    NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray *pairs = [attributes componentsSeparatedByString:@","];

    __block Class typeClass;
    NSMutableArray *typeProtocols = [NSMutableArray array];

    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSString *attribute = [pair substringToIndex:1];
        NSString *value = [pair substringFromIndex:1];

        if ([@"T" isEqualToString:attribute])
        {
            if ([@"@" isEqualToString:[value substringToIndex:1]])
            {
                if ([value length] > 3)
                {
                    NSString *objectDesignation = [value substringFromIndex:2];
                    objectDesignation = [objectDesignation substringToIndex:[objectDesignation length] - 1];

                    NSMutableArray *chunks = [[objectDesignation componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] mutableCopy];
                    NSString *classDesignation = [chunks objectAtIndex:0];
                    [chunks removeObjectAtIndex:0];

                    typeClass = [classDesignation length] ? NSClassFromString(classDesignation) : [NSObject class];

                    while ([chunks count])
                    {
                        NSString *protoName = [chunks lastObject];
                        Protocol *proto = NSProtocolFromString(protoName);
                        if (proto)
                        {
                            [typeProtocols insertObject:proto atIndex:0];
                        }
                        [chunks removeLastObject];
                    }
                }
            }
            else
            {
                typeClass = [NSObject class];
            }
        }
    }];

    if (protocols) *protocols = typeProtocols;
    return typeClass;
}

/// Dynamically added setter `set<PropertyName>:`
void EEESetPropertyValueAsAssociatedObject(id object, SEL _cmd, id value) {
    Class objectClass = [object class];
    NSString *propertyName = EEEPropertyNameFromSetter(_cmd);
    SEL associationKey = NSSelectorFromString(propertyName);

    objc_property_t property = class_getProperty(objectClass, associationKey);

    if (property)
    {
        objc_AssociationPolicy association = EEEAssociationPolicyForProperty(property, associationKey);
        [object willChangeValueForKey:propertyName];
        objc_setAssociatedObject(object, associationKey, value, association);
        [object didChangeValueForKey:propertyName];
        NSLog(@"Set associated object %@ on %@ via `%s`", value, object, associationKey);
    }
}

/// Dynamically added getter `<PropertyName>`
id EEEGetLazilyInjectedPropertyValue(id object, SEL _cmd) {
    NSString *propertyName = EEEPropertyNameFromGetter(_cmd);
    SEL associationKey = NSSelectorFromString(propertyName);

    id result = objc_getAssociatedObject(object, associationKey);

    if (!result)
    {
        NSLog(@"No associated object found on %@ via `%s`", object, associationKey);
        Class objectClass = [object class];
        objc_property_t property = class_getProperty(objectClass, [propertyName UTF8String]);

        id propertyClass = EEEClassForProperty(property, NULL);
        result = [propertyClass eee_objectFromInjector:[EEEInjector currentInjector] withIdentifier:propertyName];

        if (result)
        {
            EEESetPropertyValueAsAssociatedObject(object, EEESetterForPropertyName(propertyName), result);
            NSLog(@"Injected associated object %@ on %@ via `%s`", result, object, associationKey);
        }
    }

    return result;
}

@implementation NSObject (EEELazyInjection)

+ (void)eee_setupLazyInjectionForDynamicProperties
{
    [[EEEIntrospectProperty propertiesOfClass:self] enumerateObjectsUsingBlock:^(EEEIntrospectProperty *property, NSUInteger idx, BOOL *stop) {
        if (property.isObject && property.dynamicFlag)
        {
            NSAssert(property.customSetter == nil, @"Custom setters are not supported");
            NSAssert(property.customGetter == nil, @"Custom getters are not supported");

            SEL setter = EEESetterForPropertyName(property.name);
            Method existingSetter = class_getInstanceMethod(self, setter);
            BOOL requiresSetter = existingSetter == NULL;
            if (!requiresSetter)
            {
                NSLog(@"Setter: %@", NSStringFromSelector(method_getName(existingSetter)));
                return;
            }

            BOOL addedSetter = class_addMethod(self, setter, (IMP) EEESetPropertyValueAsAssociatedObject, "v@:@");
            if (!addedSetter)
            {
                NSLog(@"Did not add setter `%@.%@`", NSStringFromClass(self), NSStringFromSelector(setter));
                return;
            }

            SEL getter = NSSelectorFromString(property.name);
            Method existingGetter = class_getInstanceMethod(self, getter);
            BOOL requiresGetter = existingGetter == NULL;
            if (!requiresGetter)
            {
                NSLog(@"Getter: %@", NSStringFromSelector(method_getName(existingGetter)));
                return;
            }

            BOOL addedGetter = class_addMethod(self, getter, (IMP) EEEGetLazilyInjectedPropertyValue, "@@:");
            if (!addedGetter)
            {
                NSLog(@"Did not add getter `%@.%@`", NSStringFromClass(self), NSStringFromSelector(getter));
                return;
            }
        }
    }];
}

@end