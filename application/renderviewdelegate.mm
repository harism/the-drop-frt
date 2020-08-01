#import <simd/simd.h>
#import <MetalKit/MetalKit.h>
#import "renderviewdelegate.h"

@implementation RenderViewDelegate
{
    id<MTLDevice> _device;
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _commandQueue;
    id<MTLRenderPipelineState> _renderPipeline;
}

-(instancetype)initWithRenderView:(RenderView*)renderView
{
    if (self = [super init])
    {
        _device = [renderView device];
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];

        auto renderScreenFunction = [_library newFunctionWithName:@"RenderScreen"];
        auto renderFragmentFunction = [_library newFunctionWithName:@"RenderTest"];
        auto renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        [renderPipelineDescriptor setVertexFunction:renderScreenFunction];
        [renderPipelineDescriptor setFragmentFunction:renderFragmentFunction];
        [[renderPipelineDescriptor colorAttachments][0] setPixelFormat:renderView.colorPixelFormat];
        _renderPipeline = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
        [renderScreenFunction release];
        [renderFragmentFunction release];
        [renderPipelineDescriptor release];
    }
    return self;
}

-(void)dealloc
{
    [_device release];
    [_library release];
    [_commandQueue release];
    [super dealloc];
}

-(void)drawInMTKView:(nonnull MTKView*)view
{
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    if (auto renderPassDescriptor = [view currentRenderPassDescriptor])
    {
        CGSize viewportSize = [view drawableSize];
        auto viewport = (MTLViewport) { 0.0, 0.0, viewportSize.width, viewportSize.height, -1.0, 1.0 };
        auto mainEncoder = [commandBuffer parallelRenderCommandEncoderWithDescriptor:renderPassDescriptor];

        auto renderEncoder = [mainEncoder renderCommandEncoder];
        [renderEncoder setViewport:viewport];
        [renderEncoder setRenderPipelineState:_renderPipeline];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [renderEncoder endEncoding];

        [mainEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end
