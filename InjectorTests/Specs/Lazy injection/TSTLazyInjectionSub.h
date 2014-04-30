#import <Foundation/Foundation.h>
#import "TSTLazyInjectionBase.h"

@interface TSTLazyInjectionSub : TSTLazyInjectionBase

@property (nonatomic, copy) NSString *stringPropertyInSubClass;
@property (nonatomic, copy) NSDate *datePropertyInSubClass;

@end