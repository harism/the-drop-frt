#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#import "renderviewdelegate.h"

@implementation RenderViewDelegate
{
    float _timeAdjust;

    id<MTLDevice> _device;
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _commandQueue;
    
    AVAudioPlayer* _musicPlayer;

    id<MTLRenderPipelineState> _renderLogoPipeline;
}

-(instancetype)initWithRenderView:(RenderView*)renderView
{
    if (self = [super init])
    {
        _timeAdjust = 0.0;
        _device = [renderView device];
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];

        if (auto musicPath = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"mp3"])
        {
            NSURL* musicUrl = [NSURL fileURLWithPath:musicPath];
            _musicPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:musicUrl error:nil];
            [_musicPlayer play];
        }

        auto renderScreenFunction = [_library newFunctionWithName:@"RenderScreen"];
        auto renderFragmentFunction = [_library newFunctionWithName:@"RenderLogo"];
        auto renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        [renderPipelineDescriptor setVertexFunction:renderScreenFunction];
        [renderPipelineDescriptor setFragmentFunction:renderFragmentFunction];
        [[renderPipelineDescriptor colorAttachments][0] setPixelFormat:renderView.colorPixelFormat];
        _renderLogoPipeline = [_device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];
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
    [_musicPlayer release];
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

        if ((rand() % 44) == 0)
        {
            _timeAdjust += ((rand() % 1995) / 1995.0) * 0.1;
        }

        float time = [_musicPlayer currentTime] + _timeAdjust;

        auto renderEncoder = [mainEncoder renderCommandEncoder];
        [renderEncoder setViewport:viewport];
        [renderEncoder setRenderPipelineState:_renderLogoPipeline];
        [renderEncoder setFragmentBytes:&time length:sizeof(float) atIndex:0];
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
