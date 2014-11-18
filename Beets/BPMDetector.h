#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^BPMDetectionBlock)(double bpm, double confidence);

@interface BPMDetector : NSObject <AVCaptureAudioDataOutputSampleBufferDelegate>
@property(nonatomic, readonly) AVCaptureInput *input;

+ (instancetype)bpmDetectorWithCaptureInput:(AVCaptureInput *)aInput;

- (void)listenWithBlock:(BPMDetectionBlock)aHandler;
- (void)stopListening;
@end