#import "BPMDetector.h"
#import <Accelerate/Accelerate.h>
#import <aubio/aubio.h>

static uint_t const fftSize = 2048,
hopSize = fftSize/4;

@implementation BPMDetector {
    AVCaptureSession *_captureSession;
    AVCaptureAudioDataOutput *_dataOutput;
    BPMDetectionBlock _handlerBlock;
    dispatch_queue_t _detectionQueue;

    aubio_tempo_t *_tempo;
}

+ (instancetype)bpmDetectorWithCaptureInput:(AVCaptureInput * const)aInput
{
    NSParameterAssert(aInput);

    BPMDetector *detector = [self new];
    detector->_input      = aInput;

    return detector;
}

- (instancetype)init
{
    if((self = [super init])) {
        _detectionQueue = dispatch_queue_create([NSStringFromClass([self class]) UTF8String],
                                                DISPATCH_QUEUE_SERIAL);
        _dataOutput = [AVCaptureAudioDataOutput new];
        [_dataOutput setSampleBufferDelegate:self queue:_detectionQueue];
//        _dataOutput.audioSettings = @{
//                                      AVFormatIDKey: @(kAudioFormatLinearPCM),
//                                      AVSampleRateKey: @44100,
//                                      AVNumberOfChannelsKey: @1,
//                                      AVLinearPCMBitDepthKey: @32,
//                                      AVLinearPCMIsFloatKey: @YES
//                                      };

        _tempo = new_aubio_tempo("default", fftSize, hopSize, 44100);
//        aubio_tempo_set_silence(_tempo, 45);
//        aubio_tempo_set_threshold(_tempo, 50);
    }
    return self;
}

- (void)dealloc
{
    if(_captureSession)
        [self stopListening];
    del_aubio_tempo(_tempo);
}

- (void)listenWithBlock:(BPMDetectionBlock const)aHandler
{
    NSAssert(!_captureSession, @"Detection already in progress!");
    _handlerBlock = aHandler;

    _captureSession = [AVCaptureSession new];
    [_captureSession addInput:_input];
    [_captureSession addOutput:_dataOutput];
    [_captureSession startRunning];
}

- (void)stopListening
{
    NSAssert(_captureSession, @"Detection not in progress");

    [_captureSession stopRunning];
    _captureSession = nil;
    _handlerBlock   = nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{

    CMItemCount      const sampleCount = CMSampleBufferGetNumSamples(sampleBuffer);
    CMBlockBufferRef const audioBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);

    char *rawSampleData;
    CMBlockBufferGetDataPointer(audioBuffer, 0, NULL, NULL, (char **)&rawSampleData);

    CMAudioFormatDescriptionRef const format = CMSampleBufferGetFormatDescription(sampleBuffer);
    const AudioStreamBasicDescription *streamDesc = CMAudioFormatDescriptionGetStreamBasicDescription(format);
    NSAssert(streamDesc->mFormatID == kAudioFormatLinearPCM &&
             streamDesc->mChannelsPerFrame == 1 &&
             streamDesc->mBitsPerChannel == 16,
             @"Unsupported audio format");

    float * const samples = malloc(sampleCount * sizeof(float));
    vDSP_vflt16((short *)rawSampleData, 1, samples, 1, sampleCount);

    fvec_t * const inSampleVec  = new_fvec(hopSize);
    fvec_t * const beatSampleVec = new_fvec(2);

    uint_t ofs = 0;
    while(ofs < sampleCount) {
        fvec_zeros(inSampleVec);
        for(uint_t i = 0; i < MIN(hopSize, sampleCount-ofs); ++i) {
            fvec_set_sample(inSampleVec, samples[ofs+i], i);
        }
        aubio_tempo_do(_tempo, inSampleVec, beatSampleVec);
        if(beatSampleVec->data[0] != 0) {
            smpl_t const bpm        = aubio_tempo_get_bpm(_tempo);
            smpl_t const confidence = aubio_tempo_get_confidence(_tempo);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(_handlerBlock)
                    _handlerBlock(bpm, confidence);
            });
        }
        ofs += hopSize;
    }
    
    del_fvec(inSampleVec);
    del_fvec(beatSampleVec);
    free(samples);
}

@end
