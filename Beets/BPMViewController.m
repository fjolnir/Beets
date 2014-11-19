#import <AVFoundation/AVFoundation.h>

#import "BPMViewController.h"
#import "BPMView.h"
#import "BPMDetector.h"
#import "TheAmazingAudioEngine.h"
#import "AEPlaythroughChannel.h"
#ifdef BPM_USE_AUDIOBUS
#    import "Audiobus.h"
#endif

@implementation BPMViewController {
    BPMDetector *_detector;
    AEAudioController *_audioController;
#ifdef BPM_USE_AUDIOBUS
    ABAudiobusController *_audiobusController;
#endif
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    AudioStreamBasicDescription const streamDescription = [AEAudioController nonInterleavedFloatStereoAudioDescription];
    _audioController = [[AEAudioController alloc] initWithAudioDescription:streamDescription
                                                              inputEnabled:YES
                                                        useVoiceProcessing:NO];
    _audioController.avoidMeasurementModeForBuiltInMic = NO;
    _audioController.useMeasurementMode                = YES;
    _audioController.preferredBufferDuration           = 0.005;


#ifdef BPM_USE_AUDIOBUS
    _audiobusController = [[ABAudiobusController alloc] initWithApiKey:AUDIOBUS_API_KEY_HERE];

    ABReceiverPort *remotePort = [[ABReceiverPort alloc] initWithName:@"beets" title:NSLocalizedString(@"Beets", nil)];
    remotePort.clientFormat = streamDescription;
    [_audiobusController addReceiverPort:remotePort];
    [_audioController setAudiobusReceiverPort:remotePort];

    AEPlaythroughChannel *playthroughChannel = [[AEPlaythroughChannel alloc] initWithAudioController:_audioController];
    [_audioController addInputReceiver:playthroughChannel];
    [_audioController addChannels:@[playthroughChannel]];
#endif

    _detector = [BPMDetector bpmDetectorWithAudioController:_audioController];

    [_audioController start:NULL];
}

- (void)viewWillAppear:(BOOL const)aAnimated
{
    [super viewWillAppear:aAnimated];

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [_detector listenWithBlock:^(double bpm, double confidence) {
            if(confidence >= 0.2) {
                self.bpmView.bpm = bpm;
                [self.bpmView pulsate];
            } else
                self.bpmView.bpm = 0;
        }];
    }];
}
- (void)viewDidDisappear:(BOOL const)aAnimated
{
    [super viewDidDisappear:aAnimated];
    [_detector stopListening];
}

- (void)setView:(UIView * const)aView
{
    NSParameterAssert([aView isKindOfClass:[BPMView class]]);
    [super setView:aView];
}

- (BPMView *)bpmView
{
    return (BPMView *)self.view;
}
- (void)setBpmView:(BPMView *)aView
{
    self.view = aView;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
