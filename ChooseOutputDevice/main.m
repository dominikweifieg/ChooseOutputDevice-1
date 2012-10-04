//
//  main.m
//  ChooseOutputDevice
//
//  Created by Dominik Wei-Fieg on 04.10.12.
//  Copyright (c) 2012 Ars Subtilior. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreAudio/CoreAudio.h>

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if(isprint(errorString[1]) && isprint(errorString[2]) && isprint(errorString[3]) && isprint(errorString[4]))
    {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else {
        sprintf(errorString, "%d", (int) error);
    }
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

CFStringRef GetDeviceUID(CFStringRef inModelUID)
{
    CFStringRef result = NULL;
    AudioObjectPropertyAddress address = {kAudioHardwarePropertyDevices,
        kAudioObjectPropertyScopeGlobal,
        kAudioObjectPropertyElementMaster};
    
    UInt32 thePropSize;
    AudioDeviceID *theDeviceList = NULL;
    UInt32 theNumDevices = 0;
    
    CheckError(AudioObjectGetPropertyDataSize(kAudioObjectSystemObject,
                                              &address,
                                              0,
                                              NULL,
                                              &thePropSize),
               "Could not get audio property data size");
    
    // Find out how many devices are on the system
    theNumDevices = thePropSize / sizeof(AudioDeviceID);
    theDeviceList = (AudioDeviceID*)calloc(theNumDevices, sizeof(AudioDeviceID));
    
    CheckError(AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                          &address,
                                          0,
                                          NULL,
                                          &thePropSize,
                                          theDeviceList),
               "Error in AudioObjectGetPropertyData");
    
    
    CFStringRef theModelUID;
    for (UInt32 i=0; i < theNumDevices; i++)
    {
        // get the Model UID
        thePropSize = sizeof(CFStringRef);
        address.mSelector = kAudioDevicePropertyModelUID;
        address.mScope = kAudioObjectPropertyScopeGlobal;
        address.mElement = kAudioObjectPropertyElementMaster;
    
        CheckError(AudioObjectGetPropertyData(theDeviceList[i],
                                              &address,
                                              0,
                                              NULL,
                                              &thePropSize,
                                              &theModelUID),
                   "Error in AudioObjectGetPropertyDatan");
        
        if (CFStringCompare(theModelUID, inModelUID, kCFCompareEqualTo) == kCFCompareEqualTo) {
            //found the ModelUID
            address.mSelector = kAudioDevicePropertyDeviceUID;
            CheckError(AudioObjectGetPropertyData(theDeviceList[i],
                                                  &address,
                                                  0,
                                                  NULL,
                                                  &thePropSize,
                                                  &result),
                       "Error in AudioObjectGetPropertyData");
            break;
        }
    }
    return result;
}

OSStatus GetDeviceID(CFStringRef *inDeviceUID, AudioDeviceID *outDeviceID)
{
    UInt32 propertySize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress defaultDeviceProperty;
    defaultDeviceProperty.mSelector = kAudioHardwarePropertyDeviceForUID;
    defaultDeviceProperty.mScope = kAudioObjectPropertyScopeGlobal;
    defaultDeviceProperty.mElement = kAudioObjectPropertyElementMaster;
    
    AudioValueTranslation translation = {};
    translation.mInputData = inDeviceUID;
    translation.mInputDataSize = sizeof(inDeviceUID);
    translation.mOutputData = outDeviceID;
    translation.mOutputDataSize = propertySize;
    
    UInt32 inSize = sizeof(translation);
    
    OSStatus result = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                 &defaultDeviceProperty,
                                                 0,
                                                 NULL,
                                                 &inSize,
                                                 &translation);
    if (result) {
        printf("Error in AudioObjectGetPropertyData: %d\n", result);
    }
    
    return result;
}

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        CFStringRef modelUID;
        if (argc == 2) {
            modelUID = CFStringCreateWithCString(kCFAllocatorDefault, argv[1], kCFStringEncodingASCII);
        } else {
            modelUID = CFStringCreateWithCString(kCFAllocatorDefault, "AppleHDA:40", kCFStringEncodingASCII);
        }
        
        CFStringRef deviceUID = GetDeviceUID(modelUID);
        
        if (deviceUID) {
            
            AudioDeviceID deviceID;
            
            OSStatus result = GetDeviceID(&deviceUID, &deviceID);
            
            if (result == noErr) {
                printf("The device ID is: %d", deviceID);
            }
        }
        
    }
    return 0;
}

