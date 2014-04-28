#import <Kiwi/Kiwi.h>
#import "EEEInjector.h"
#import "TSTLazyInjectionBase.h"
#import "TSTLazyInjectionSub.h"

SPEC_BEGIN(NSObject_EEELazyInjectionSpec)

        describe(@"NSObject+EEELazyInjection", ^{
            __block EEEInjector *injector;

            beforeEach(^{
                injector = [EEEInjector setCurrentInjector:[[EEEInjector alloc] init] force:YES];
            });

            context(@"with a setup", ^{
                __block NSDate *date = nil;

                beforeEach(^{
                    date = [NSDate date];
                    [[injector mapClass:[NSDate class] overwriteExisting:YES] toObject:date];
                    [[injector mapClass:[NSString class] withIdentifier:@"stringPropertyInSubClass" overwriteExisting:YES] toObject:@"Concrete"];
                    [[injector mapClass:[NSString class] withIdentifier:@"stringPropertyInBaseClass" overwriteExisting:YES] toObject:@"Abstract"];
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
        });

        SPEC_END
