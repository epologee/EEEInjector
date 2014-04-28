#import <Kiwi/Kiwi.h>
#import "EEEInjector.h"
#import "TSTConformingObject.h"
#import "TSTProtocolInjectionObject.h"

SPEC_BEGIN(TSTConformingObjectSpec)

        describe(@"TSTConformingObject", ^{
            __block EEEInjector *injector;

            beforeEach(^{
                injector = [EEEInjector setCurrentInjector:[[EEEInjector alloc] init] force:YES];
                injector.allowImplicitMapping = YES;
            });

            it(@"maps to a conforming class", ^{
                [[[injector mapProtocol:@protocol(TSTConformable)] toConformingClass:[TSTConformingObject class]] asSingleton];

                TSTProtocolInjectionObject *object = [[TSTProtocolInjectionObject alloc] init];
                [TSTConformingObject eee_injectWithInjector:injector];
                TSTConformingObject *sut = (TSTConformingObject *) object.conformingObject;
                [[sut should] beKindOfClass:[TSTConformingObject class]];
            });
        });

        SPEC_END
