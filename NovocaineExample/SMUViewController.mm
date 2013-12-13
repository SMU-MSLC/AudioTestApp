//
//  SMUViewController.m
//  NovocaineExample
//
//  Created by Eric Larson on 12/12/13.
//  Copyright (c) 2013 Eric Larson. All rights reserved.
//

#import "SMUViewController.h"

@interface SMUViewController ()

@end

@implementation SMUViewController

float frequency;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated{
    //overloading this function
    [super viewWillAppear:animated];
    
    ringBuffer = new RingBuffer(32768,2);
    audioManager = [Novocaine audioManager];
    
    // Measure dBs
    // ==================================================
//    __block float dbVal = 0.0;
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//    
//        // square the vector
//        vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
//        
//        // take the mean
//        float meanVal = 0.0;
//        vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
//    
//        float one = 1.0;
//        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
//        dbVal = dbVal + 0.2*(meanVal - dbVal);
//        printf("Decibel level: %f\n", dbVal);
//        
//    }];

    //===================================================
    // Get Max
    // ==================================================
//    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
//        
//        // get the max
//        float maxVal = 0.0;
//        vDSP_maxv(data, 1, &maxVal, numFrames*numChannels);
//
//        printf("Max Audio Value: %f\n", maxVal);
//        
//    }];

    frequency = 600.0;
    __block float phase = 0.0;
    __block float samplingRate = audioManager.samplingRate;
    __block double phaseIncrement = frequency / samplingRate;
    [audioManager setOutputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels)
     {

         for (int i=0; i < numFrames; ++i)
         {
             for (int iChannel = 0; iChannel < numChannels; ++iChannel)
             {
                 float theta = phase * M_PI * 2;
                 data[i*numChannels + iChannel] = sin(theta);
             }
             phase += phaseIncrement;
             if (phase > 1.0) phase = -1;
         }
     }];
    
}

@end
