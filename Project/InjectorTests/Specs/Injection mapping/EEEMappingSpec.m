//
//  EEEMappingSpec.m
//  Injector
//
//  Created by Eric-Paul Lecluse on 28-04-14.
//  Copyright 2014 epologee. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "EEEMapping.h"
#import "TSTMappable.h"
#import "TSTMappableConformingObject.h"
#import "TSTNonConformingObject.h"
#import "TSTConformingObject.h"

SPEC_BEGIN(EEEMappingSpec)

        describe(@"EEEMapping", ^{
            let(number5, ^{return @5;});

            context(@"class block chain mapping", ^{
                __block id <EEEClassBlockChainMappingStart> mapping;

                describe(@"to object", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapClass:[NSNumber class]];
                    });

                    it(@"returns a target object", ^{
                        mapping.toObject(number5);
                        [[[(EEEMapping *) mapping targetObject] should] equal:number5];
                    });

                    it(@"can be single serving", ^{
                        mapping.toObject(number5).removeAfterUse(YES);

                        [[[(EEEMapping *) mapping targetObject] should] equal:number5];
                        [[[(EEEMapping *) mapping targetObject] should] beNil];
                    });
                });

                context(@"to subclass", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapClass:[NSArray class]];
                    });

                    it(@"returns a target object", ^{
                        mapping.toSubclass([NSMutableArray class]);

                        [[[(EEEMapping *) mapping targetObject] should] beKindOfClass:[NSMutableArray class]];
                    });

                    it(@"can be single serving", ^{
                        mapping.toSubclass([NSMutableArray class]).removeAfterUse(YES);

                        NSMutableArray *mutableArray = [(EEEMapping *) mapping targetObject];
                        [mutableArray addObject:@"mutable"];
                        [mutableArray addObject:@"array"];

                        [[[(EEEMapping *) mapping targetObject] should] beNil];
                    });

                    it(@"keeps the object around as a pseudo-singleton", ^{
                        mapping.toSubclass([NSMutableArray class]).keepReference(YES);

                        NSMutableArray *mutableArray = [(EEEMapping *) mapping targetObject];
                        [mutableArray addObject:@"mutable"];
                        [mutableArray addObject:@"array"];

                        [[[(EEEMapping *) mapping targetObject] should] haveCountOf:2];
                    });
                });

                describe(@"to block", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapClass:[NSNumber class]];
                    });

                    it(@"returns the object from the block", ^{
                        mapping.toBlock(^id {return @10;});

                        [[[(EEEMapping *) mapping targetObject] should] equal:@10];
                    });

                    it(@"can remove the block after use", ^{
                        mapping.toBlock(^id {return @10;}).removeAfterUse(YES);

                        [[[(EEEMapping *) mapping targetObject] should] equal:@10];
                        [[[(EEEMapping *) mapping targetObject] should] beNil];
                    });

                    it(@"keeps the object around as a pseudo-singleton", ^{
                        mapping.toBlock(^id {return [NSMutableString stringWithString:@"Hello"];}).keepReference(YES);

                        NSMutableString *string = [(EEEMapping *) mapping targetObject];
                        [string appendString:@" World!"];

                        [[[(EEEMapping *) mapping targetObject] should] equal:@"Hello World!"];
                    });
                });
            });

            context(@"protocol block chain mapping", ^{
                __block id <EEEProtocolBlockChainMappingStart> mapping;

                describe(@"to object", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapProtocol:@protocol(TSTMappable)];
                    });

                    it(@"returns a target object, regardless of conformity", ^{
                        mapping.toObject(number5);
                        [[[(EEEMapping *) mapping targetObject] should] equal:number5];
                    });
                });

                context(@"to conforming class", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapProtocol:@protocol(TSTMappable)];
                    });

                    it(@"returns a target object", ^{
                        mapping.toConformingClass([TSTMappableConformingObject class]);

                        [[[(EEEMapping *) mapping targetObject] should] beKindOfClass:[TSTMappableConformingObject class]];
                    });

                    it(@"raises when not conforming", ^{
                        [[theBlock(^{mapping.toConformingClass([TSTNonConformingObject class]);}) should] raise];
                    });
                });

                describe(@"to block", ^{
                    beforeEach(^{
                        mapping = [EEEMapping mapProtocol:@protocol(TSTMappable)];
                    });

                    it(@"returns the block object", ^{
                        __block id uniqueObject = nil;

                        mapping.toBlock(^id {
                            uniqueObject = [[TSTConformingObject alloc] init];
                            return uniqueObject;
                        });

                        [[[(EEEMapping *) mapping targetObject] should] equal:uniqueObject];
                    });
                });
            });
        });

        SPEC_END
