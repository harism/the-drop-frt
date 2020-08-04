#import <AVFoundation/AVFoundation.h>
#import <MetalKit/MetalKit.h>
#import "renderviewdelegate.h"

@implementation RenderViewDelegate
{
    float _timeAdjust;
    NSDate* _demoStartDate;

    id<MTLDevice> _device;
    id<MTLLibrary> _library;
    id<MTLCommandQueue> _commandQueue;
    
    AVAudioPlayer* _musicPlayer;

    id<MTLRenderPipelineState> _renderMainPipeline;
    id<MTLRenderPipelineState> _renderLogoPipeline;

    int _backgroundIndex;
    NSTimeInterval _backgroundTimer;
    NSArray* _renderBackgroundPipelines;

    id<MTLTexture> _logoTexture;
    id<MTLTexture> _backgroundTexture;
    MTLRenderPassDescriptor* _logoRenderPassDescriptor;
    MTLRenderPassDescriptor* _backgroundRenderPassDescriptor;
}

+(nonnull id<MTLRenderPipelineState>)loadFunction:(nonnull id<MTLLibrary>)library functionName:(nonnull NSString*)functionName
{
    auto renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderDescriptor.vertexFunction = [library newFunctionWithName:@"RenderScreenQuad"];
    renderDescriptor.fragmentFunction = [library newFunctionWithName:functionName];
    renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
    return [[library device] newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];
}

-(instancetype)initWithRenderView:(RenderView*)renderView
{
    if (self = [super init])
    {
        _timeAdjust = 0.0;
        _demoStartDate = [NSDate date];
        _device = [renderView device];
        _library = [_device newDefaultLibrary];
        _commandQueue = [_device newCommandQueue];

        _backgroundIndex = 0;
        _backgroundTimer = 0.0;

        if (auto musicPath = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"mp3"])
        {
            NSURL* musicUrl = [NSURL fileURLWithPath:musicPath];
            _musicPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:musicUrl error:nil];
        }

        auto renderScreenFunction = [_library newFunctionWithName:@"RenderScreenQuad"];
        auto renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderDescriptor.vertexFunction = renderScreenFunction;

        renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"RenderMain"];
        renderDescriptor.colorAttachments[0].pixelFormat = renderView.colorPixelFormat;
        _renderMainPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];

        renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"RenderLogo"];
        renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
        _renderLogoPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];

        [renderScreenFunction release];
        [renderDescriptor release];

        _renderBackgroundPipelines = [[NSArray alloc] initWithObjects:
            [RenderViewDelegate loadFunction:_library functionName:@"RenderStarNest"],
            [RenderViewDelegate loadFunction:_library functionName:@"RenderVignette"],
            [RenderViewDelegate loadFunction:_library functionName:@"RenderSpores"],
            nil];


        MTLTextureDescriptor* logoTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float width:1920 height:1080 mipmapped:NO];
        logoTextureDescriptor.storageMode = MTLStorageModePrivate;
        logoTextureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        _logoTexture = [_device newTextureWithDescriptor:logoTextureDescriptor];
        [logoTextureDescriptor release];

        MTLTextureDescriptor* backgroundTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float width:1280 height:720 mipmapped:NO];
        backgroundTextureDescriptor.storageMode = MTLStorageModePrivate;
        backgroundTextureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        _backgroundTexture = [_device newTextureWithDescriptor:backgroundTextureDescriptor];
        [backgroundTextureDescriptor release];

        _logoRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _logoRenderPassDescriptor.colorAttachments[0].texture = _logoTexture;
        _logoRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        _logoRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

        _backgroundRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _backgroundRenderPassDescriptor.colorAttachments[0].texture = _backgroundTexture;
        _backgroundRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        _backgroundRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
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
    const auto currentTimeSeconds = [[NSDate date] timeIntervalSinceDate:_demoStartDate];

    if ([_musicPlayer isPlaying] == NO)
    {
        if (currentTimeSeconds >= 10.0 && currentTimeSeconds < 20.0)
        {
            [_musicPlayer play];
        }
    }

    if (currentTimeSeconds >= 10.0 && _backgroundTimer <= currentTimeSeconds)
    {
        _backgroundIndex = rand() % [_renderBackgroundPipelines count];
        _backgroundTimer = currentTimeSeconds + 1.0;
    }

    if ((rand() % 44) == 0)
    {
        _timeAdjust += ((rand() % 1995) / 1995.0) * 0.1;
    }

    const float time = [_musicPlayer currentTime] + _timeAdjust;
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    if (auto renderPassDescriptor = [view currentRenderPassDescriptor])
    {
        auto logoEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_logoRenderPassDescriptor];
        [logoEncoder setViewport: (MTLViewport) { 0.0, 0.0, 1920, 1080, -1.0, 1.0 }];
        [logoEncoder setRenderPipelineState:_renderLogoPipeline];
        [logoEncoder setFragmentBytes:&time length:sizeof(float) atIndex:0];
        [logoEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [logoEncoder endEncoding];

        auto backgroundEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_backgroundRenderPassDescriptor];
        [backgroundEncoder setViewport: (MTLViewport) { 0.0, 0.0, 1280, 720, -1.0, 1.0 }];
        [backgroundEncoder setRenderPipelineState:[_renderBackgroundPipelines objectAtIndex:_backgroundIndex]];
        [backgroundEncoder setFragmentBytes:&time length:sizeof(float) atIndex:0];
        [backgroundEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [backgroundEncoder endEncoding];

        CGSize viewportSize = [view drawableSize];
        auto mainEncoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
        [mainEncoder setViewport:(MTLViewport) { 0.0, 0.0, viewportSize.width, viewportSize.height, -1.0, 1.0 }];
        [mainEncoder setFragmentTexture:_logoTexture atIndex:0];
        [mainEncoder setFragmentTexture:_backgroundTexture atIndex:1];
        [mainEncoder setRenderPipelineState:_renderMainPipeline];
        [mainEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [mainEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
    }

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end
