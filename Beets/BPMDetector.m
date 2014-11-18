#import "BPMDetector.h"
#import <Accelerate/Accelerate.h>
#import <aubio/aubio.h>
#import "TheAmazingAudioEngine.h"
#import <CoreAudio/CoreAudioTypes.h>
#import "Audiobus.h"

static uint_t const fftSize = 1024,
hopSize = fftSize/4;

@interface BPMDetector () <AEAudioReceiver>
@property(nonatomic) AEAudioControllerAudioCallback receiverCallback;
@end

static void _BPMDetector_audioCallback(__unsafe_unretained BPMDetector       *self,
                                       __unsafe_unretained AEAudioController *audioController,
                                       void                                  *source,
                                       const AudioTimeStamp                  *time,
                                       UInt32                                 frames,
                                       AudioBufferList                       *audio);

@implementation BPMDetector {
    @public
    AEAudioController *_audioController;
    BPMDetectionBlock _handlerBlock;

    aubio_tempo_t *_tempo;
}
@dynamic running;

+ (instancetype)bpmDetectorWithAudioController:(AEAudioController *)aController
{
    BPMDetector *detector = [self new];
    detector->_audioController = aController;
    [aController addInputReceiver:detector];
    return detector;
}

- (instancetype)init
{
    if((self = [super init])) {
        _tempo = new_aubio_tempo("default", fftSize, hopSize, 44100);
//        aubio_tempo_set_silence(_tempo, 45);
//        aubio_tempo_set_threshold(_tempo, 50);
    }
    return self;
}

- (void)dealloc
{
    del_aubio_tempo(_tempo);
}

- (AEAudioControllerAudioCallback)receiverCallback
{
    return &_BPMDetector_audioCallback;
}

- (void)listenWithBlock:(BPMDetectionBlock const)aHandler
{
    NSAssert(!_handlerBlock, @"Detection already in progress!");
    _handlerBlock = aHandler;
}

- (void)stopListening
{
    NSAssert(_handlerBlock, @"Detection not in progress");
    _handlerBlock = nil;
}

- (BOOL)isRunning
{
    return _handlerBlock != nil;
}
@end

static void _BPMDetector_audioCallback(__unsafe_unretained BPMDetector       *self,
                                       __unsafe_unretained AEAudioController *audioController,
                                       void                                  *source,
                                       const AudioTimeStamp                  *time,
                                       UInt32                                 frames,
                                       AudioBufferList                       *audio)
{
        float * const samples = audio->mBuffers[0].mData;

        fvec_t * const inSampleVec  = new_fvec(hopSize);
        fvec_t * const beatSampleVec = new_fvec(2);

        uint_t ofs = 0;
        while(ofs < frames) {
            fvec_zeros(inSampleVec);
            fvec_zeros(beatSampleVec);
            for(uint_t i = 0; i < MIN(hopSize, frames-ofs); ++i) {
                fvec_set_sample(inSampleVec, samples[ofs+i], i);
            }
            aubio_tempo_do(self->_tempo, inSampleVec, beatSampleVec);
            if(beatSampleVec->data[0] != 0) {
                smpl_t const bpm        = aubio_tempo_get_bpm(self->_tempo);
                smpl_t const confidence = aubio_tempo_get_confidence(self->_tempo);
                printf(">> %.3f BPM @ %.2f confidence; last: %.2fs; [%.2f, %.2f]\n",
                       bpm, confidence, aubio_tempo_get_last_s(self->_tempo),
                       beatSampleVec->data[0], beatSampleVec->data[1]);

                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self->_handlerBlock)
                        self->_handlerBlock(bpm, confidence);
                });
            }
            ofs += hopSize;
        }

        del_fvec(inSampleVec);
        del_fvec(beatSampleVec);
}