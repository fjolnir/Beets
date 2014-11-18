#import <AVFoundation/AVFoundation.h>

#import "BPMViewController.h"
#import "BPMDetector.h"
#import "TheAmazingAudioEngine.h"
#import "AEPlaythroughChannel.h"
#import "Audiobus.h"

@implementation BPMViewController {
    BPMDetector *_detector;
    CATextLayer *_bpmLayer;
    AEAudioController *_audioController;
    ABAudiobusController *_audiobusController;
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



    _audiobusController = [[ABAudiobusController alloc] initWithApiKey:@"MTQxNzUwMzU3MCoqKkJlZXRzKioqQmVldHMuYXVkaW9idXM6Ly8=:luJd/XPwMQ4DcgNyEwHnpZF1M8yMLhYiBI1yPmmxoA75Oeo79iYsDwPKp9Pas0O9k25vbQ5XYTEjBo1EXW7WMcN95iaogBhu0j4dFcYhj1gBybOfMauD0umJQkrYFMwI"];

    ABReceiverPort *remotePort = [[ABReceiverPort alloc] initWithName:@"beets" title:NSLocalizedString(@"Beets", nil)];
    remotePort.clientFormat = streamDescription;
    [_audiobusController addReceiverPort:remotePort];
    [_audioController setAudiobusReceiverPort:remotePort];

    AEPlaythroughChannel *playthroughChannel = [[AEPlaythroughChannel alloc] initWithAudioController:_audioController];
    [_audioController addInputReceiver:playthroughChannel];
    [_audioController addChannels:@[playthroughChannel]];

    _detector = [BPMDetector bpmDetectorWithAudioController:_audioController];

    _bpmLayer = [CATextLayer new];
    _bpmLayer.fontSize = 60;
    _bpmLayer.font = CGFontCreateWithFontName(CFSTR("HelveticaNeue-Bold"));
    _bpmLayer.foregroundColor = [[UIColor whiteColor] CGColor];
    _bpmLayer.frame = self.view.bounds;
    _bpmLayer.alignmentMode = kCAAlignmentCenter;
    _bpmLayer.wrapped = NO;
    _bpmLayer.contentsScale = [[UIScreen mainScreen] scale];
    [self.view.layer addSublayer:_bpmLayer];

    [_audioController start:NULL];
}

- (void)viewWillAppear:(BOOL const)aAnimated
{
    [super viewWillAppear:aAnimated];

    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        [_detector listenWithBlock:^(double bpm, double confidence) {
            if(confidence < 0.2) {
                _bpmLayer.string = @"...";
                [self.view setNeedsLayout];
                return;
            }

            _bpmLayer.string = [NSString stringWithFormat:@"%.2f", bpm];

            CABasicAnimation *bgAnim = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
            bgAnim.toValue = (__bridge id)[[UIColor whiteColor] CGColor];
            bgAnim.duration = 0.1;
            bgAnim.autoreverses = YES;
            [self.view.layer addAnimation:bgAnim forKey:@"bpmFlash"];

            CABasicAnimation *labelAnim = [CABasicAnimation animationWithKeyPath:@"foregroundColor"];
            labelAnim.toValue = (__bridge id)[[UIColor blackColor] CGColor];
            labelAnim.duration = 0.1;
            labelAnim.autoreverses = YES;
            [_bpmLayer addAnimation:labelAnim forKey:@"bpmFlash"];

            [self.view setNeedsLayout];
        }];
    }];
}
- (void)viewDidDisappear:(BOOL const)aAnimated
{
    [super viewDidDisappear:aAnimated];
    [_detector stopListening];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    _bpmLayer.position = (CGPoint) {
        CGRectGetMidX(self.view.bounds),
        CGRectGetMidY(self.view.bounds)
    };
    _bpmLayer.bounds = (CGRect) {
        0, 0,
        self.view.bounds.size.width,
        [_bpmLayer.string sizeWithAttributes:@{
            NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Bold" size:60]
        }].height
    };
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
