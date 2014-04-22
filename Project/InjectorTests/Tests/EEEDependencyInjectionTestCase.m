// Copyright (c) 2012 Twelve Twenty (http://twelvetwenty.nl/)
//
// Permission is hereby granted, free of charge, to any unifiedCard obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "EEEDependencyInjectionTestCase.h"

#import "EEEInjector.h"

#import "EEEDISimpleObject.h"
#import "EEEDIBaseObject.h"
#import "EEEDIConcreteObject.h"

#import "EEEDISimpleSingleton.h"
#import "EEEDIBaseSingleton.h"
#import "EEEDIConcreteSingleton.h"

#import "EEEDIInjectableObject.h"

@interface EEEDependencyInjectionTestCase ()

@property (nonatomic, strong) EEEInjector *injector;
@property (nonatomic, strong) id existingObject;
@property (nonatomic, strong) NSArray *simpleListObject;

@end


@implementation EEEDependencyInjectionTestCase

- (void)setUp
{
    self.injector = [[EEEInjector alloc] init];
    
	[self.injector mapClass:[EEEDISimpleObject class]];
    [[self.injector mapClass:[EEEDIBaseObject class]] toSubclass:[EEEDIConcreteObject class]];
    [[self.injector mapClass:[EEEDISimpleSingleton class]] asSingleton];
    [[[self.injector mapClass:[EEEDIBaseSingleton class]] toSubclass:[EEEDIConcreteSingleton class]] asSingleton];

    self.existingObject = @[@"Hello", @"Object"];
    [[self.injector mapClass:[NSArray class]] toObject:self.existingObject];
    
    self.simpleListObject = @[@"Another", @"List"];
    [[self.injector mapClass:[NSArray class] withIdentifier:@"simpleList"] toObject:self.simpleListObject];

    [[self.injector mapClass:[NSDictionary class]] singleServing];

    [self.injector mapClass:[EEEDIInjectableObject class]];
}

- (void)tearDown
{
    self.injector = nil;
    self.existingObject = nil;
}

- (void)testSetup
{
	XCTAssertTrue(YES, @"Setup works");
}

- (void)testNoMapping
{
    BOOL assertionThrown = NO;
    
    @try {
        NSMutableSet *nilSet = [NSMutableSet eee_objectFromInjector:self.injector];
        XCTAssertNil(nilSet, @"Request of a non-mapped class returns nil.");
    }
    @catch (NSException *exception) {
        assertionThrown = YES;
    }

    XCTAssertTrue(assertionThrown, @"Request of a non-mapped class throws an error.");
}

- (void)testSimpleSpawnMapping
{
    EEEDISimpleObject *objectA = [EEEDISimpleObject eee_objectFromInjector:self.injector];
    
    XCTAssertTrue([objectA isKindOfClass:[EEEDISimpleObject class]], @"Requested object for mapped class returns an instance of that class.");

    EEEDISimpleObject *objectB = [EEEDISimpleObject eee_objectFromInjector:self.injector];

    XCTAssertFalse(objectA == objectB, @"Consecutive requested objects with simple mapping return newly allocated objects.");
}

- (void)testOnceMapping
{
    NSDictionary *dictionaryA = [NSDictionary eee_objectFromInjector:self.injector];
    
    XCTAssertTrue([dictionaryA isKindOfClass:[NSDictionary class]], @"Requested object for mapped class returns an instance of that class.");
    
    BOOL assertionThrown = NO;
    
    @try {
        NSDictionary *dictionaryB = [NSDictionary eee_objectFromInjector:self.injector];
        XCTAssertNil(dictionaryB, @"Second requested of a `once` object returns nil.");
    }
    @catch (NSException *exception) {
        assertionThrown = YES;
    }
    
    XCTAssertTrue(assertionThrown, @"Second request of a `once` object throws an error.");
}


- (void)testSingletonMapping
{
    EEEDISimpleSingleton *objectA = [EEEDISimpleSingleton eee_objectFromInjector:self.injector];
    
    XCTAssertTrue([objectA isKindOfClass:[EEEDISimpleSingleton class]], @"Requested object for mapped class returns an instance of that class.");
    
    EEEDISimpleSingleton *objectB = [EEEDISimpleSingleton eee_objectFromInjector:self.injector];
    
    XCTAssertTrue(objectA == objectB, @"Consecutive requested singletons return the same object every time.");
}

- (void)testSingletonSubclassMapping
{
    EEEDIBaseSingleton *objectA = [EEEDIBaseSingleton eee_objectFromInjector:self.injector];
    
    XCTAssertTrue([objectA isKindOfClass:[EEEDIConcreteSingleton class]], @"Requested object for mapped base class returns an instance of the concrete subclass.");
    
    EEEDIBaseSingleton *objectB = [EEEDIBaseSingleton eee_objectFromInjector:self.injector];
    
    XCTAssertTrue(objectA == objectB, @"Consecutive requested singletons return the same object every time.");
}

- (void)testObjectMapping
{
    NSArray *object = [NSArray eee_objectFromInjector:self.injector];
    
    XCTAssertEqual(object, self.existingObject, @"Requested object for object-mapping returns the existing object");
}

- (void)testPropertyInjection
{
    EEEDIInjectableObject *injectable = [EEEDIInjectableObject eee_objectFromInjector:self.injector];
                                         
    XCTAssertTrue([injectable isKindOfClass:[EEEDIInjectableObject class]], @"Requested object for mapped class returns an instance of that class.");
                                         
    XCTAssertTrue([injectable.simpleInjectedObject isKindOfClass:[EEEDISimpleObject class]], @"Property marked with the injectable protocol is injected with a proper object.");
    
    XCTAssertNil(injectable.simpleNotInjectedObject, @"Property not marked with the injectable protocol is not injected, even if the property's type actually implements that protocol.");
}

- (void)testPropertyObjectInjection
{
    EEEDIInjectableObject *injectable = [EEEDIInjectableObject eee_objectFromInjector:self.injector];
    
    XCTAssertTrue(injectable.simpleList == self.simpleListObject, @"Object marked with the injectable protocol is injected with the proper object based on its name/identifier.");
}

@end
