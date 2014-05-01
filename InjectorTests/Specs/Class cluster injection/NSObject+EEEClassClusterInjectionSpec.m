//
//  NSObject+EEEClassClusterInjectionSpec.m
//  Injector
//
//  Created by Eric-Paul Lecluse on 01-05-14.
//  Copyright 2014 epologee. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "TSTVisibleClusterObject.h"
#import "TSTHiddenClusterObject.h"

SPEC_BEGIN(NSObject_EEEClassClusterInjectionSpec)

        describe(@"TSTVisibleClusterObject", ^{
            it(@"alloc inits", ^{
                TSTVisibleClusterObject *sut = [[TSTVisibleClusterObject alloc] init];
                [[sut should] beKindOfClass:[TSTVisibleClusterObject class]];
                [[sut should] beMemberOfClass:[TSTHiddenClusterObject class]];
            });

            it(@"copies", ^{
                TSTVisibleClusterObject *sut = [[TSTVisibleClusterObject alloc] init];

                TSTVisibleClusterObject *copiedSut = [sut copy];
                [[copiedSut should] beKindOfClass:[TSTVisibleClusterObject class]];
                [[copiedSut should] beMemberOfClass:[TSTHiddenClusterObject class]];
            });

            it(@"knows about basic equality", ^{
                TSTVisibleClusterObject *sut = [[TSTVisibleClusterObject alloc] init];

                TSTVisibleClusterObject *copiedSut = [sut copy];

                [[copiedSut should] equal:sut];
            });
        });

        SPEC_END
