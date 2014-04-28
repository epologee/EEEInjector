//
//  EEEInjector+ProtocolInjectionSpec.m
//  Injector
//
//  Created by Eric-Paul Lecluse on 28-04-14.
//  Copyright 2014 epologee. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "EEEInjector.h"
#import "TSTConformingObject.h"

SPEC_BEGIN(EEEInjector_ProtocolInjectionSpec)

        describe(@"EEEInjector", ^{
            describe(@"Protocol injection", ^{
                __block EEEInjector *injector;

                beforeEach(^{
                    injector = [EEEInjector setCurrentInjector:[[EEEInjector alloc] init] force:YES];
                    injector.allowImplicitMapping = YES;
                });

                it(@"maps", ^{
                    [[[injector mapProtocol:@protocol(TSTConformable)] toConformingClass:[TSTConformingObject class]] asSingleton];

                    id object = [(id <EEEInjectorInternals>) injector objectForMappedProtocol:@protocol(TSTConformable) withIdentifier:nil];
                    [[object should] beKindOfClass:[TSTConformingObject class]];
                });
            });
        });

        SPEC_END
