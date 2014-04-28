#import <Foundation/Foundation.h>

@protocol TSTConformable <NSObject>

- (BOOL)behave;

@end

@interface TSTConformingObject : NSObject <TSTConformable>
@end