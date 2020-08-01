#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import "renderview.h"
#import "renderviewdelegate.h"

@implementation RenderView
{
    RenderViewDelegate* _renderViewDelegate;
}

-(instancetype)frameRect:(const CGRect&)frameRect
{
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (self = [super initWithFrame:frameRect device:device])
    {
        _renderViewDelegate = [[RenderViewDelegate alloc] initWithRenderView:self];
        [self setDelegate:_renderViewDelegate];
     }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

-(BOOL)mouseDownCanMoveWindow
{
    return NO;
}

@end
