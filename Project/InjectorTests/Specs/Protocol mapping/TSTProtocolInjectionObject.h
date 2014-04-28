#import <Foundation/Foundation.h>

@protocol TSTConformable;

@interface TSTProtocolInjectionObject : NSObject

@property(nonatomic, strong) id <TSTConformable> conformingObject;

@end