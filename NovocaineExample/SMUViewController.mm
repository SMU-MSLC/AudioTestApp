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
    
    // MEASURE SOME DECIBELS!
    // ==================================================
    __block float dbVal = 0.0;
    [audioManager setInputBlock:^(float *data, UInt32 numFrames, UInt32 numChannels) {
    
        vDSP_vsq(data, 1, data, 1, numFrames*numChannels);
        float meanVal = 0.0;
        vDSP_meanv(data, 1, &meanVal, numFrames*numChannels);
    
        float one = 1.0;
        vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
        dbVal = dbVal + 0.2*(meanVal - dbVal);
        printf("Decibel level: %f\n", dbVal);
        
    }];
}

@end
