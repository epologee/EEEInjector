#import <Foundation/Foundation.h>

@protocol TSTMappable;

@interface TSTNonConformingObject : NSObject

@property(nonatomic, strong) id <TSTMappable> mappableConformingObject;

@end