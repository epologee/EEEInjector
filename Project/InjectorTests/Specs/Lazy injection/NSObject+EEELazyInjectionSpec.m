#import <Kiwi/Kiwi.h>
#import "EEEInjector.h"
#import "TSTLazyInjectionBase.h"
#import "TSTLazyInjectionSub.h"
#import "TSTMappable.h"
#import "TSTMappableConformingObject.h"
#import "TSTNonConformingObject.h"

SPEC_BEGIN(NSObject_EEELazyInjectionSpec)

        describe(@"NSObject+EEELazyInjection", ^{
            __block EEEInjector *injector;

            beforeEach(^{
                injector = [EEEInjector setCurrentInjector:[[EEEInjector alloc] init] force:YES];
            });

            context(@"class based properties", ^{
                __block NSDate *date = nil;

                beforeEach(^{
                    date = [NSDate date];
                    injector.mapClass([NSDate class]).toObject(date);
                    injector.mapClass([NSString class]).toObject(date);
                    injector.mapClassWithIdentifier([NSString class], @"stringPropertyInSubClass").toObject(@"Concrete");
                    injector.mapClassWithIdentifier([NSString class], @"stringPropertyInBaseClass").toObject(@"Abstract");
                });

                it(@"injects properties from the subclass", ^{
                    TSTLazyInjectionSub *sut = [[TSTLazyInjectionSub alloc] init];
                    [[sut.datePropertyInSubClass should] equal:date];
                    [[sut.stringPropertyInSubClass should] equal:@"Concrete"];
                    [[sut.stringPropertyInBaseClass should] equal:@"Abstract"];
                });

                it(@"allows properties to be set", ^{
                    TSTLazyInjectionSub *sut = [[TSTLazyInjectionSub alloc] init];
                    [[sut.datePropertyInSubClass should] equal:date];

                    NSDate *ancient = [NSDate dateWithTimeIntervalSince1970:0];
                    sut.datePropertyInSubClass = ancient;
                    [[sut.datePropertyInSubClass should] equal:ancient];
                });
            });

            context(@"protocol based properties", ^{
                beforeEach(^{
                    injector.mapProtocol(@protocol(TSTMappable)).toConformingClass([TSTMappableConformingObject class]);
                });

                it(@"injects properties from the subclass", ^{
                    TSTNonConformingObject *sut = [[TSTNonConformingObject alloc] init];
                    id object = sut.mappableConformingObject;
                    [[object should] beKindOfClass:[TSTMappableConformingObject class]];
                });
            });
        });

        SPEC_END
