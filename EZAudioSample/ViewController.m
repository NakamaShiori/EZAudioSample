//
//  ViewController.m
//  EZAudioSample
//
//  Created by N on 2015/05/19.
//  Copyright (c) 2015年 Nakama. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic,strong) AVAudioPlayer *audioPlayer;
@property IBOutlet UIButton *recordButton;
@property IBOutlet UIButton *playButton;

@end

@implementation ViewController
@synthesize audioPlot;
@synthesize microphone;
@synthesize recorder;

#pragma mark - Initialization
-(id)init {
    self = [super init];
    if(self){
        [self initializeViewController];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if(self){
        [self initializeViewController];
    }
    return self;
}

#pragma mark - Initialize View Controller Here
-(void)initializeViewController {
    // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    self.microphone = [EZMicrophone microphoneWithDelegate:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    /*
     Customizing the audio plot's look
     */
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    // Waveform color
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];
    // Plot type
    self.audioPlot.plotType        = EZPlotTypeRolling;
    // Fill
    self.audioPlot.shouldFill      = YES;
    // Mirror
    self.audioPlot.shouldMirror    = YES;
    
    /*
     Start the microphone
     */
    [self.microphone startFetchingAudio];
    
    self.isRecording = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)playStart:(id)sender{
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed:0.984 green:0.471 blue:0.525 alpha:1.0];
    
    // Update microphone state
    [self.microphone stopFetchingAudio];
    
    // Update recording state
    self.isRecording = NO;
    [self.recordButton setTitle:@"Record Start" forState:UIControlStateNormal];
    
    // Create Audio Player
    if( self.audioPlayer )
    {
        if( self.audioPlayer.playing )
        {
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
    
    // Close the audio file
    if( self.recorder )
    {
        [self.recorder closeAudioFile];
    }
    
    NSError *err;
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[self testFilePathURL]
                                                              error:&err];
    [self.audioPlayer play];
    self.audioPlayer.delegate = self;
    [self.playButton setTitle:@"Stop Play" forState:UIControlStateNormal];
    
}

-(IBAction)recordStart:(id)sender{
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.569 green: 0.82 blue: 0.478 alpha: 1];
    
    [self.playButton setTitle:@"Start Play" forState:UIControlStateNormal];
    if( self.audioPlayer )
    {
        if( self.audioPlayer.playing )
        {
            [self.audioPlayer stop];
        }
        self.audioPlayer = nil;
    }
    self.playButton.hidden = NO;
    
    if(self.isRecording)
    {
        
        // Background color
        self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
        
        [self.recorder closeAudioFile];
        self.isRecording = NO;
        [self.recordButton setTitle: @"Record Start" forState:UIControlStateNormal];
    }
    else
    {
        /*
         Create the recorder
         */
        self.recorder = [EZRecorder recorderWithDestinationURL:[self testFilePathURL]
                                                  sourceFormat:self.microphone.audioStreamBasicDescription
                                           destinationFileType:EZRecorderFileTypeM4A];
        self.isRecording = YES;
        [self.recordButton setTitle: @"Record Stop" forState:UIControlStateNormal];
    }
}

#pragma mark - EZMicrophoneDelegate
// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
    });
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder. This is happening on the audio thread - any UI updating needs a GCD main queue block. This will keep appending data to the tail of the audio file.
    if( self.isRecording ){
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
    
}

#pragma mark - AVAudioPlayerDelegate
/*
 Occurs when the audio player instance completes playback
 */
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    // Background color
    self.audioPlot.backgroundColor = [UIColor colorWithRed: 0.984 green: 0.71 blue: 0.365 alpha: 1];
    
    self.audioPlayer = nil;
    
    [self.microphone startFetchingAudio];
}

#pragma mark - Utility
-(NSArray*)applicationDocuments {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
}

-(NSString*)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}


-(NSURL*)testFilePathURL {
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}


@end
