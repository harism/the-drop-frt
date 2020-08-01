#import <MetalKit/MetalKit.h>
#import "renderview.h"

@interface RenderViewDelegate : NSObject<MTKViewDelegate>

-(nullable instancetype)initWithRenderView:(nonnull RenderView*)renderView;

-(void)drawInMTKView:(nonnull MTKView*)view;

-(void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size;

@end
