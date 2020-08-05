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
    id<MTLRenderPipelineState> _renderEnginePipeline;

    int _backgroundIndex;
    NSTimeInterval _backgroundTimer;
    NSArray* _renderBackgroundPipelines;

    id<MTLTexture> _engineTexture;
    id<MTLTexture> _backgroundTexture;
    MTLRenderPassDescriptor* _engineRenderPassDescriptor;
    MTLRenderPassDescriptor* _backgroundRenderPassDescriptor;

    int _powerIndex;
    float _peakPowerValues[256];
    float _averagePowerValues[256];
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

        _powerIndex = 0;
        memset(_peakPowerValues, 0, sizeof(float) * 256);
        memset(_averagePowerValues, 0, sizeof(float) * 256);

        if (auto musicPath = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"mp3"])
        {
            NSURL* musicUrl = [NSURL fileURLWithPath:musicPath];
            _musicPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:musicUrl error:nil];
            _musicPlayer.meteringEnabled = YES;
        }

        auto renderScreenFunction = [_library newFunctionWithName:@"RenderScreenQuad"];
        auto renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        renderDescriptor.vertexFunction = renderScreenFunction;

        renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"RenderMain"];
        renderDescriptor.colorAttachments[0].pixelFormat = renderView.colorPixelFormat;
        _renderMainPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];

        renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"RenderEngine"];
        renderDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormatRGBA16Float;
        _renderEnginePipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:nil];

        [renderScreenFunction release];
        [renderDescriptor release];

        _renderBackgroundPipelines = [[NSArray alloc] initWithObjects:
            [RenderViewDelegate loadFunction:_library functionName:@"RenderBlank"],
            [RenderViewDelegate loadFunction:_library functionName:@"RenderBackground"],
            [RenderViewDelegate loadFunction:_library functionName:@"RenderDark"],
            nil];

        MTLTextureDescriptor* engineTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float width:1920 height:1080 mipmapped:NO];
        engineTextureDescriptor.storageMode = MTLStorageModePrivate;
        engineTextureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        _engineTexture = [_device newTextureWithDescriptor:engineTextureDescriptor];
        [engineTextureDescriptor release];

        MTLTextureDescriptor* backgroundTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA16Float width:1920 height:1080 mipmapped:NO];
        backgroundTextureDescriptor.storageMode = MTLStorageModePrivate;
        backgroundTextureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageRenderTarget;
        _backgroundTexture = [_device newTextureWithDescriptor:backgroundTextureDescriptor];
        [backgroundTextureDescriptor release];

        _engineRenderPassDescriptor = [MTLRenderPassDescriptor new];
        _engineRenderPassDescriptor.colorAttachments[0].texture = _engineTexture;
        _engineRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionLoad;
        _engineRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

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

    [_musicPlayer updateMeters];
    const float time = [_musicPlayer currentTime] + _timeAdjust;
    const float peakPower = [_musicPlayer peakPowerForChannel:0];
    const float averagePower = [_musicPlayer averagePowerForChannel:0];

    _peakPowerValues[_powerIndex] = peakPower;
    _averagePowerValues[_powerIndex] = averagePower;

    if (auto renderPassDescriptor = [view currentRenderPassDescriptor])
    {
        id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
        auto engineEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_engineRenderPassDescriptor];
        [engineEncoder setViewport: (MTLViewport) { 0.0, 0.0, 1920, 1080, -1.0, 1.0 }];
        [engineEncoder setRenderPipelineState:_renderEnginePipeline];
        [engineEncoder setFragmentBytes:&time length:sizeof(float) atIndex:0];
        [engineEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [engineEncoder endEncoding];

        auto backgroundEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_backgroundRenderPassDescriptor];
        [backgroundEncoder setViewport: (MTLViewport) { 0.0, 0.0, 1920, 1080, -1.0, 1.0 }];
        [backgroundEncoder setRenderPipelineState:[_renderBackgroundPipelines objectAtIndex:_backgroundIndex]];
        [backgroundEncoder setFragmentBytes:&time length:sizeof(float) atIndex:0];
        [backgroundEncoder setFragmentBytes:&_powerIndex length:sizeof(int) atIndex:1];
        [backgroundEncoder setFragmentBytes:&_peakPowerValues length:sizeof(float) * 256 atIndex:2];
        [backgroundEncoder setFragmentBytes:&_averagePowerValues length:sizeof(float) * 256 atIndex:3];
        [backgroundEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [backgroundEncoder endEncoding];

        CGSize viewportSize = [view drawableSize];
        auto mainEncoder = [commandBuffer renderCommandEncoderWithDescriptor: renderPassDescriptor];
        [mainEncoder setViewport:(MTLViewport) { 0.0, 0.0, viewportSize.width, viewportSize.height, -1.0, 1.0 }];
        [mainEncoder setFragmentTexture:_engineTexture atIndex:0];
        [mainEncoder setFragmentTexture:_backgroundTexture atIndex:1];
        [mainEncoder setRenderPipelineState:_renderMainPipeline];
        [mainEncoder drawPrimitives:MTLPrimitiveTypeTriangleStrip vertexStart:0 vertexCount:4];
        [mainEncoder endEncoding];

        [commandBuffer presentDrawable:view.currentDrawable];
        [commandBuffer commit];
    }

    _powerIndex = ++_powerIndex & 0xFF;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

@end
