//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "AppDelegate.h"

static vDSP_Length const FFTViewControllerFFTWindowSize = 4096;

NSString *note;
NSString *pre_note;
float maxFrequency;

@implementation AppDelegate

- (void) awakeFromNib {
    [super awakeFromNib];
    
    //
    // Customizing the audio plot that'll show the playback
    self.playingAudioPlot.plotType = EZPlotTypeBuffer;
    self.recordingAudioPlot.backgroundColor = [NSColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    self.recordingAudioPlot.color           = [NSColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    self.recordingAudioPlot.plotType        = EZPlotTypeRolling;
    self.recordingAudioPlot.shouldFill      = YES;
    self.recordingAudioPlot.shouldMirror    = YES;
    
    self.recordingManager = [[RecordingManager alloc] init];
    self.recordingManager.delegate = self;
    
    //
    // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
    //
    self.fft = [EZAudioFFTRolling fftWithWindowSize:FFTViewControllerFFTWindowSize sampleRate:self.recordingManager.microphone.audioStreamBasicDescription.mSampleRate
                                           delegate:self];
    
    [self.recordingManager.microphone startFetchingAudio];
    
    //
    // Initialize UI components
    //
    [self setTitle:@"Microphone On" forButton:self.microphoneSwitch];
    [self setTitle:@"Start" forButton:self.recordSwitch];
    self.playingStateLabel.stringValue = @"Not Playing";
    self.playButton.enabled = NO;
    
    _volumeSlider.maxValue = 1.0;
    _volumeSlider.minValue = 0.0;
    _volumeSlider.doubleValue = 1.0;
    [_volumeSlider setTarget:self];
    [_volumeSlider setAction:@selector(volumeChanged:)];
    pre_note = @"";
//    _showStringTimer = [NSTimer scheduledTimerWithTimeInterval:0.3f
//                                                        target:self selector:@selector(view_string) userInfo:nil repeats:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    
    
}

- (IBAction) volumeChanged:(id)sender {
    
    NSSlider *slider = sender;
    double value = [slider doubleValue];
    [self.recordingManager controlVolume:value];
}

//------------------------------------------------------------------------------
#pragma mark - Actions
//------------------------------------------------------------------------------

- (void)playFile:(id)sender
{
    
}

//------------------------------------------------------------------------------

- (void)toggleMicrophone:(id)sender
{
    
}

- (void)toggleRecording:(id)sender
{
    if (self.recordingManager.isRecording == FALSE) {
        //iShow_Test_Feb_27.wav
        NSDateFormatter *dateformate=[[NSDateFormatter alloc]init];
        [dateformate setDateFormat:@"MM_dd_yyyy"]; // Date formater
        NSString *date = [dateformate stringFromDate:[NSDate date]];
        NSString* audioFile = [NSString stringWithFormat:@"%@%@%@.wav",NSHomeDirectory(),@"/Documents/",date];
        [self.recordingManager startRecordingAtPath:audioFile];
        _showStringTimer = [NSTimer scheduledTimerWithTimeInterval:0.2f
                                                            target:self selector:@selector(view_string) userInfo:nil repeats:YES];
    } else {
        [self.recordingManager stopRecordingCompletionBlock:^{
            [_showStringTimer invalidate];
        }];
    }
    NSString *title = self.recordingManager.isRecording ? @"Stop" : @"Start";
    [self setTitle:title forButton:self.recordSwitch];
}
#pragma mark - RecordingManagerDelegate
    
- (void) didStartRecordingToOutputFileAt:(NSURL *)outputURL {
    self.playButton.enabled = YES;
    self.window.title = outputURL.path;
}
    
- (void) didFinishRecordingToOutputFileAt:(NSURL *)outputURL {
    self.window.title = @"RecordFile";
}
    
- (void) updateAudioPlotBuffer:(float *)buffer withBufferSize:(UInt32)bufferSize {
    [self.recordingAudioPlot updateBuffer:buffer
                               withBufferSize:bufferSize];
    //
    // Calculate the FFT, will trigger EZAudioFFTDelegate
    //
    [self.fft computeFFTWithBuffer:buffer withBufferSize:bufferSize];
    [_playingAudioPlot updateBuffer:buffer
                          withBufferSize:bufferSize];
}
    
- (void) recorderUpdatedCurrentTime:(NSString *)formattedCurrentTime {
    self.currentTimeLabel.stringValue = formattedCurrentTime;
}
    
    //------------------------------------------------------------------------------
#pragma mark - EZAudioFFTDelegate
    //------------------------------------------------------------------------------
    
- (void) fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
    {
        maxFrequency = [fft maxFrequency];
        note = [EZAudioUtilities noteNameStringForFrequency:maxFrequency
                                                            includeOctave:YES];
        
        __weak typeof (self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.recordingAudioPlot updateBuffer:fftData withBufferSize:(UInt32)bufferSize];
        });
    }

- (void) view_string
{
    NSLog(@"++this is log++");
    __weak typeof (self) weakSelf = self;
    if ( maxFrequency < 20.0){
        weakSelf.maxFrequencyLabel.stringValue = [NSString stringWithFormat:@"Highest Note: %@ \nFrequency: %.2f", pre_note, maxFrequency];
    }else{
        weakSelf.maxFrequencyLabel.stringValue = [NSString stringWithFormat:@"Highest Note: %@ \nFrequency: %.2f", note, maxFrequency];
        pre_note = note;
    }
}

//------------------------------------------------------------------------------
#pragma mark - Utility
//------------------------------------------------------------------------------

- (void)setTitle:(NSString *)title forButton:(NSButton *)button
{
    NSDictionary *attributes = @{ NSForegroundColorAttributeName : [NSColor whiteColor] };
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title
                                                                          attributes:attributes];
    button.attributedTitle = attributedTitle;
    button.attributedAlternateTitle = attributedTitle;
}

@end
