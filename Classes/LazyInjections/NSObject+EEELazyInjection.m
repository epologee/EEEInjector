#import <objc/runtime.h>
#import "NSObject+EEELazyInjection.h"
#import "EEEInjector.h"
#import "EEEIntrospectProperty.h"

NSString *EEEKeyWithSetterName(NSString *setter) {
    if ([setter length] >= 4)
    {
        NSMutableString *key = [NSMutableString string];
        [key appendString:[[setter substringWithRange:NSMakeRange(3, 1)] lowercaseString]];
        [key appendString:[setter substringWithRange:NSMakeRange(4, setter.length - 4)]];
        return key;
    }
    else
    {
        [NSException raise:NSInvalidArgumentException format:@"setter name should be at least 5 characters long"];
        return nil;
    }
}

NSString *EEESetterNameWithKey(NSString *key) {
    NSMutableString *setter = [NSMutableString stringWithString:@"set"];
    [setter appendString:[[key substringWithRange:NSMakeRange(0, 1)] uppercaseString]];
    [setter appendString:[key substringWithRange:NSMakeRange(1, key.length - 1)]];
    return setter;
}

objc_AssociationPolicy EEEAssociationPolicyForProperty(objc_property_t property, char const *key) {

    NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray *pairs = [attributes componentsSeparatedByString:@","];

    __block BOOL nonatomic = NO;
    __block objc_AssociationPolicy association = OBJC_ASSOCIATION_ASSIGN;

    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSString *attribute = [pair substringToIndex:1];
        NSString *value = [pair substringFromIndex:1];

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

    __block BOOL nonatomic = NO;
    __block objc_AssociationPolicy association = OBJC_ASSOCIATION_ASSIGN;

    __block Class typeClass;
    NSMutableArray *typeProtocols = [NSMutableArray array];

    [pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
        NSString *attribute = [pair substringToIndex:1];
        NSString *value = [pair substringFromIndex:1];

        if ([@"T" isEqualToString:attribute])
        {
            // type encoding
            NSString *typeEncoding = [value length] ? value : @"id";

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
void EEESetPropertyValueAsAssociatedObject(NSObject *object, SEL _cmd, id value) {
    Class objectClass = [object class];
    NSString *selector = NSStringFromSelector(_cmd);
    NSString *key = EEEKeyWithSetterName(selector);
    char const *utf8Key = [key UTF8String];

    objc_property_t property = class_getProperty(objectClass, utf8Key);

    if (property)
    {
        objc_AssociationPolicy association = EEEAssociationPolicyForProperty(property, utf8Key);
        [object willChangeValueForKey:key];
        objc_setAssociatedObject(object, utf8Key, value, association);
        [object didChangeValueForKey:key];
    }
}

/// Dynamically added getter `<PropertyName>`
id EEEGetLazilyInjectedPropertyValue(NSObject *object, SEL _cmd) {
    NSString *key = NSStringFromSelector(_cmd);
    char const *utf8Key = [key UTF8String];

    id result = objc_getAssociatedObject(object, utf8Key);

    if (!result)
    {
        objc_property_t property = class_getProperty([object class], utf8Key);

        id propertyClass = EEEClassForProperty(property, NULL);
        result = [propertyClass eee_objectFromInjector:[EEEInjector currentInjector]];

        if (result)
        {
            SEL setter = NSSelectorFromString(EEESetterNameWithKey(key));
            EEESetPropertyValueAsAssociatedObject(object, setter, result);
        }
    }

    return result;
}

@implementation NSObject (EEELazyInjection)

+ (BOOL)eee_setupLazyInjectionForDynamicProperties
{
    __block BOOL addedGetter = NO;
    __block BOOL addedSetter = NO;

    [[EEEIntrospectProperty propertiesOfClass:self] enumerateObjectsUsingBlock:^(EEEIntrospectProperty *property, NSUInteger idx, BOOL *stop) {
        if (property.isObject && property.dynamicFlag)
        {
            NSAssert(property.customSetter == nil, @"Custom setters are not supported");
            NSAssert(property.customGetter == nil, @"Custom getters are not supported");

            SEL setter = NSSelectorFromString(EEESetterNameWithKey(property.name));
            SEL getter = NSSelectorFromString(property.name);

            BOOL requiresSetter = class_getInstanceMethod([self class], setter) == NULL;
            BOOL requiresGetter = class_getInstanceMethod([self class], getter) == NULL;

            if (requiresGetter && requiresSetter)
            {
                char const *setterTypes = [[NSString stringWithFormat:@"v@:%@@", property.typeEncoding] UTF8String];
                addedSetter = class_addMethod([self class], setter, (IMP) EEESetPropertyValueAsAssociatedObject, setterTypes);
                if (addedSetter)
                {
                    addedGetter = class_addMethod([self class], getter, (IMP) EEEGetLazilyInjectedPropertyValue, "@@:");
                }
            }
        }
    }];

    return addedGetter && addedSetter;
}

@end