//
//  ViewController.h
//  EZAudioSample
//
//  Created by N on 2015/05/19.
//  Copyright (c) 2015年 Nakama. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "EZAudio.h"

@interface ViewController : UIViewController<AVAudioPlayerDelegate,EZMicrophoneDelegate>

/**
 Use a OpenGL based plot to visualize the data coming in
 */
@property (nonatomic,weak) IBOutlet EZAudioPlotGL *audioPlot;

/**
 A flag indicating whether we are recording or not
 */
@property (nonatomic,assign) BOOL isRecording;

/**
 The microphone component
 */
@property (nonatomic,strong) EZMicrophone *microphone;

/**
 The recorder component
 */
@property (nonatomic,strong) EZRecorder *recorder;

// By default this will record a file to the application's documents directory (within the application's sandbox)
#define kAudioFilePath @"EZAudioTest.m4a"

@end

