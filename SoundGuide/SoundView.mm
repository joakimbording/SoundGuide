//
//  SoundView.m
//  SoundGuide
//
//  Created by Joakim Bording on 17.02.12 - joakim@bording.no - joakim.bording.no
//  This work is shared under the creative common license: Attribution-NonCommercial ShareAlike 3.0 Unported 
//  http://creativecommons.org/licenses/by-nc-sa/3.0/
//
//  Author should always be credited 
//

#import "SoundView.h"

void ERRCHECK(FMOD_RESULT result);

@implementation SoundView

// FMOD Spesific error check
void ERRCHECK(FMOD_RESULT result)
{
    if (result != FMOD_OK) {
        fprintf(stderr, "FMOD error! (%d) %s\n", result, FMOD_ErrorString(result));
        exit(-1);
    }
}

-(id) initWithDistance:(double) distFac {
    self = [super init];
    if(self){
        [self fmodSetup];
        [self eventsSetup];
        distanceFactor = distFac;   
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
    if (eventSystem) eventSystem->release();
    eventSystem = NULL;    
}

-(void) fmodSetup {
    NSLog(@"Initializing FMOD");
    
    FMOD_RESULT result = FMOD_OK;
    char buffer[200] = {0};
    
    // FMOD Setup
    eventSystem = NULL;
    masterCategory  = NULL;
    
    result = FMOD::EventSystem_Create(&eventSystem); 
    ERRCHECK(result);
    
    FMOD_IPHONE_EXTRADRIVERDATA extradriverdata; 
    memset(&extradriverdata, 0, sizeof(FMOD_IPHONE_EXTRADRIVERDATA));
    extradriverdata.sessionCategory = FMOD_IPHONE_SESSIONCATEGORY_MEDIAPLAYBACK; 
    extradriverdata.forceMixWithOthers = true;
    
    result = eventSystem->init(32, FMOD_INIT_NORMAL | FMOD_INIT_ENABLE_PROFILE, &extradriverdata, FMOD_EVENT_INIT_NORMAL);
    ERRCHECK(result);
    
    // Turns down the volume of music playing to let icons be heard
    result = FMOD_IPhone_DuckOtherAudio(true); ERRCHECK(result);
    
    [[NSString stringWithFormat:@"%@/AudioCompass.fev", [[NSBundle mainBundle] resourcePath]] getCString:buffer maxLength:200 encoding:NSASCIIStringEncoding];
    result = eventSystem->load(buffer, NULL, NULL);
    ERRCHECK(result);   
}

-(void) eventsSetup {
    FMOD_RESULT result = FMOD_OK;
    
    // Load Event sounds
    result = eventSystem->getEvent("AudioCompass/Audicons/ApplePurrPandoraNav2", FMOD_EVENT_DEFAULT, &wayPointEvent1);
    ERRCHECK(result);
    
    result = eventSystem->getEvent("AudioCompass/Audicons/ApplePurrPandoraNav", FMOD_EVENT_DEFAULT, &wayPointEvent2);
    ERRCHECK(result);
    
    result = eventSystem->getEvent("AudioCompass/Audicons/ApplePurrPandoraNav", FMOD_EVENT_DEFAULT, &endpointEvent);
    ERRCHECK(result);    
    
    result = eventSystem->getEvent("AudioCompass/Audicons/Success", FMOD_EVENT_DEFAULT, &successEvent);
    ERRCHECK(result);      
    
    result = eventSystem->getEvent("AudioCompass/Audicons/Knips", FMOD_EVENT_DEFAULT, &clickEvent);
    ERRCHECK(result);  
    
    result = eventSystem->getCategory("master", &masterCategory);
    ERRCHECK(result);
    
    result = wayPointEvent1->getParameter("BeaconAngle", &wayPointParam1);
    ERRCHECK(result);    
    
    result = wayPointEvent2->getParameter("BeaconAngle", &wayPointParam2);
    ERRCHECK(result);   
    
    result = endpointEvent->getParameter("BeaconAngle", &endpointParam);
    ERRCHECK(result);       
    
    result = wayPointParam1->setValue(0.0f);
    ERRCHECK(result);

    result = wayPointParam2->setValue(0.0f);
    ERRCHECK(result);
    
    result = endpointParam->setValue(0.0f);
    ERRCHECK(result);
    
    result = eventSystem->update();
    ERRCHECK(result);
}

-(float) calculateVolumeFromDistance:(double) distance {
    float vol;
    if((distance / distanceFactor) < 1.0f){
        vol = 1.0f - (distance / (distanceFactor));
    } else {
        vol = 0.0f;
    }
    //NSLog(@"FMOD distance:%0.1f , %0.1f",vol,distanceFactor);
    return vol;
}

-(void) playSound:(NSString*) soundType fromAngle:(double) soundAngle fromDistance:(double) soundDistance minVolume:(double) minVol {
    NSLog(@"FMOD playSound Ang:%0.1f Typ:%@ Dist:%0.1f Min:%0.1f",soundAngle,soundType,soundDistance,minVol);
    FMOD_RESULT result = FMOD_OK;  
    
    float vol = [self calculateVolumeFromDistance:soundDistance];
    if(soundAngle > 180) soundAngle = (360 - soundAngle)*-1;
    
    if(vol < minVol) vol = minVol;
    
    if(vol > 0.0f){
        
        if([soundType isEqualToString:@"Waypoint"]){
            result = wayPointParam1->setValue(soundAngle);
            ERRCHECK(result);    

            result = wayPointEvent1->setVolume((float)vol);
            ERRCHECK(result);      

            result = wayPointEvent1->stop();
            ERRCHECK(result);            
            
            result = wayPointEvent1->start();
            ERRCHECK(result);
            
            NSLog(@"FMOD Play:wayPointEvent1");
            
        } else if([soundType isEqualToString:@"NextWaypoint"]){
            
            result = wayPointParam2->setValue(soundAngle);
            ERRCHECK(result);    
            
            result = wayPointEvent2->setVolume((float)vol);
            ERRCHECK(result);      
            
            result = wayPointEvent2->stop();
            ERRCHECK(result);
            
            result = wayPointEvent2->start();
            ERRCHECK(result);
            
            NSLog(@"FMOD Play:wayPointEvent2");
            
        } else if([soundType isEqualToString:@"Endpoint"]){
            result = endpointParam->setValue(soundAngle);
            ERRCHECK(result);    
            
            result = endpointEvent->setVolume((float)vol);
            ERRCHECK(result);      

            result = endpointEvent->stop();
            ERRCHECK(result);            
            
            result = endpointEvent->start();
            ERRCHECK(result);
            
            NSLog(@"FMOD Play:endpointEvent");            
            
        }
    }    
}

-(void) updateSound:(NSString*) soundType fromAngle:(double) soundAngle fromDistance:(double) soundDistance minVolume:(double) minVol{
    FMOD_RESULT result = FMOD_OK;  
    
    float vol = [self calculateVolumeFromDistance:soundDistance];
    if(soundAngle > 180) soundAngle = (360 - soundAngle)*-1;
    
    if(vol < minVol) vol = minVol;    
    
    if(vol > 0.0f && wayPointParam1){
        
        if([soundType isEqualToString:@"Waypoint"]){
            result = wayPointParam1->setValue(soundAngle);
            ERRCHECK(result);    
            
            result = wayPointEvent1->setVolume((float)vol);
            ERRCHECK(result);      
            
            result = eventSystem->update();
            ERRCHECK(result);
            
        } else if([soundType isEqualToString:@"NextWaypoint"]){
           
            result = wayPointParam2->setValue(soundAngle);
            ERRCHECK(result);    
            
            result = wayPointEvent2->setVolume((float)vol);
            ERRCHECK(result);      
            
            result = eventSystem->update();
            ERRCHECK(result);
            
            
        } else if([soundType isEqualToString:@"Endpoint"]){
            result = endpointParam->setValue(soundAngle);
            ERRCHECK(result);    
            
            result = endpointEvent->setVolume((float)vol);
            ERRCHECK(result);      
            
            result = eventSystem->update();
            ERRCHECK(result);
            
        }
    }
}

-(void) closeSound:(NSString*) soundType {
    NSLog(@"FMOD closeSound");
}

-(BOOL) isSoundPlaying:(NSString*) soundType {
    return YES;
}

-(void) playAfterLoop:(NSTimer *)timer  {
    FMOD_RESULT result = FMOD_OK;  
    result = successEvent->start();
    ERRCHECK(result);    
}


-(void) playSuccess {
    FMOD_RESULT result = FMOD_OK;  
    result = successEvent->start();
    ERRCHECK(result);
}

-(void) playClick {
    FMOD_RESULT result = FMOD_OK;  
    result = clickEvent->start();
    ERRCHECK(result);    
}

@end
