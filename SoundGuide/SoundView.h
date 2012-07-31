//
//  SoundView.h
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import <Foundation/Foundation.h>

#import "fmod_event.hpp"
#import "fmod_errors.h"
#import "fmodiphone.h"

@interface SoundView : NSObject {  
    bool                soundPlaying;
    bool                playEventInQue;
    double              distanceFactor;
    
    //FMOD
    FMOD::EventSystem   *eventSystem;  
    FMOD::Channel       *channel1;
    FMOD::EventCategory *masterCategory;
    FMOD_VECTOR         listenerpos;
    
    FMOD::Event         *successEvent;
    FMOD::Event         *wayPointEvent1;
    FMOD::Event         *wayPointEvent2;
    FMOD::Event         *endpointEvent;
    FMOD::Event         *clickEvent;     
    FMOD::EventParameter *wayPointParam1;
    FMOD::EventParameter *wayPointParam2;    
    FMOD::EventParameter *endpointParam; 
    
}

- (id)       initWithDistance:(double) distFac;
- (void)     fmodSetup;
- (void)     eventsSetup;
- (void)     playSound:(NSString*) soundType fromAngle:(double) soundAngle fromDistance:(double) soundDistance minVolume:(double) minVol;
- (void)     updateSound:(NSString*) soundType fromAngle:(double) soundAngle fromDistance:(double) soundDistance minVolume:(double) minVol;
- (void)     closeSound:(NSString*) soundType;
- (BOOL)     isSoundPlaying:(NSString*) soundType;
- (void)     playSuccess;
- (void)     playClick;

@end
