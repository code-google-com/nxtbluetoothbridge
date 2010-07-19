//
//  nxtOPCodes.h
//  iNXT
//
//  Created by Daniel Siemer on 3/26/09.
//

/*
 Most of the NXT Code is derived from Matt Harrington's LegoNXTRemote project
 Liscenced under the MIT Liscence
 
 The MIT License
 
 Copyright (c) 2009 Matt Harrington
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

/*! Message Codes.  These codes specify message type and specify if the command requires a return value or acknowledgement. */
enum {
   kNXTRet   = 0x00, /*!< Command returns a value */
   kNXTNoRet = 0x80, /*!< Command does not return a value */
   kNXTSysOP = 0x01  /*!< Command is a system operation */
};


/*! Operation Codes.  This is a list of command operations.  Commands typically control sensors or servos, or request information. */
enum {
   kNXTStartProgram          = 0x00, /*!< Start Program Op Code */
   kNXTStopProgram           = 0x01, /*!< Stop Program Op Code */
   kNXTPlaySoundFile         = 0x02, /*!< Play Sound File Op Code */
   kNXTPlayTone              = 0x03, /*!< Play Tone Op Code */
   kNXTSetOutputState        = 0x04, /*!< Set Output State Op Code */
   kNXTSetInputMode          = 0x05, /*!< */
   kNXTGetOutputState        = 0x06, /*!< */
   kNXTGetInputValues        = 0x07, /*!< */
   kNXTResetScaledInputValue = 0x08, /*!< */
   kNXTMessageWrite          = 0x09, /*!< */
   kNXTResetMotorPosition    = 0x0A, /*!< */
   kNXTGetBatteryLevel       = 0x0B, /*!< */
   kNXTStopSoundPlayback     = 0x0C, /*!< */
   kNXTKeepAlive             = 0x0D, /*!< */
   kNXTLSGetStatus           = 0x0E, /*!< */
   kNXTLSWrite               = 0x0F, /*!< */
   kNXTLSRead                = 0x10, /*!< */
   kNXTGetCurrentProgramName = 0x11, /*!< */
   kNXTMessageRead           = 0x13  /*!< */
};


/*! Port Specifiers.  These enums specify sensor or motor ports. */
enum {
   kNXTSensor1  = 0x00, /*!< Sensor Port 1 */
   kNXTSensor2  = 0x01, /*!< Sensor Port 2 */
   kNXTSensor3  = 0x02, /*!< Sensor Port 3 */
   kNXTSensor4  = 0x03, /*!< Sensor Port 4 */
   
   kNXTMotorA   = 0x00, /*!< Motor Port A */
   kNXTMotorB   = 0x01, /*!< Motor Port B */
   kNXTMotorC   = 0x02, /*!< Motor Port C */
   kNXTMotorAll = 0xFF  /*!< All Motors */
};


/*! Servo Modes.  These modes alter the behavior of servos. */
enum {
   kNXTCoast     = 0x00, /*!< */
   kNXTMotorOn   = 0x01, /*!< */
   kNXTBrake     = 0x02, /*!< */
   kNXTRegulated = 0x04  /*!< */
};


/*! Servo Regulation Modes.  These regulation modes alter the behavior of servos. */
enum {
   kNXTRegulationModeIdle       = 0x00, /*!< */
   kNXTRegulationModeMotorSpeed = 0x01, /*!< */
   kNXTRegulationModeMotorSync  = 0x02  /*!< */
};


/*! Servo Run States.  These regulation modes alter the behavior of servos. */
enum {
   kNXTMotorRunStateIdle        = 0x00, /*!< */
   kNXTMotorRunStateRampUp      = 0x10, /*!< */
   kNXTMotorRunStateRunning     = 0x20, /*!< */
   kNXTMotorRunStateRampDown    = 0x40  /*!< */
};

/*! Sensor types (user facing).  Used to list sensors we offer the user as options */
enum {
   kNXTTouchIndex          = 0,
   kNXTSoundIndex          = 1,
   kNXTLightActiveIndex    = 2,
   kNXTLightPassiveIndex   = 3,
   kNXTSonarIndex          = 4,
   kNXTColorFullIndex      = 5,
   kNXTColorRedIndex       = 6,
   kNXTColorGreenIndex     = 7,
   kNXTColorBlueIndex      = 8,
   kNXTColorNoneIndex      = 9,
   kNXTCustomIndex         = 254,
   kNXTMotorIndex          = 255
};

/*! Sensor Types (NXT facing).  Specify sensor type and operation. */
enum {
   kNXTNoSensor            = 0x00, /*!< */
   kNXTSwitch              = 0x01, /*!< */
   kNXTTemperature         = 0x02, /*!< */
   kNXTReflection          = 0x03, /*!< */
   kNXTAngle               = 0x04, /*!< */
   kNXTLightActive         = 0x05, /*!< */
   kNXTLightInactive       = 0x06, /*!< */
   kNXTSoundDB             = 0x07, /*!< */
   kNXTSoundDBA            = 0x08, /*!< */
   kNXTCustom              = 0x09, /*!< */
   kNXTLowSpeed            = 0x0A, /*!< */
   kNXTLowSpeed9V          = 0x0B, /*!< */
   kNXTNoOfSensorTypes     = 0x0C,  /*!< */
   kNXTColorFull           = 0x0D,
   kNXTColorRed            = 0x0E,
   kNXTColorGreen          = 0x0F,
   kNXTColorBlue           = 0x10,
   kNXTColorNone           = 0x11
};


/*! Sensor Modes.  These modes control sensor operation. */
enum {
   kNXTRawMode             = 0x00, /*!< */
   kNXTBooleanMode         = 0x20, /*!< */
   kNXTTransitionCntMode   = 0x40, /*!< */
   kNXTPeriodCounterMode   = 0x60, /*!< */
   kNXTPCTFullScaleMode    = 0x80, /*!< */
   kNXTCelciusMode         = 0xA0, /*!< */
   kNXTFahrenheitMode      = 0xC0, /*!< */
   kNXTAngleStepsMode      = 0xE0, /*!< */
   kNXTSlopeMask           = 0x1F, /*!< */
   kNXTModeMask            = 0xE0  /*!< */
};

/*! Display types for rotation values from motors */
enum {
   kNXTTachoCount = 1,
   kNXTBlockTachoCount = 2,
   kNXTRotationCount = 3
};

/*! Color values returned by the NXT Color sensor. */
enum {
   kNXTColorConstBlack = 1,
   kNXTColorConstBlue = 2,
   kNXTColorConstGreen = 3,
   kNXTColorConstYellow = 4,
   kNXTColorConstRed = 5,
   kNXTColorConstWhite = 6
};

/*! Command Return Values.  Success and error codes returned by commands. */
enum {
   kNXTSuccess                 = 0x00, /*!< */
   kNXTPendingCommunication    = 0x20, /*!< */
   kNXTMailboxEmpty            = 0x40, /*!< */
   kNXTNoMoreHandles           = 0x81, /*!< */
   kNXTNoSpace                 = 0x82, /*!< */
   kNXTNoMoreFiles             = 0x83, /*!< */
   kNXTEndOfFileExpected       = 0x84, /*!< */
   kNXTEndOfFile               = 0x85, /*!< */
   kNXTNotALinearFile          = 0x86, /*!< */
   kNXTFileNotFound            = 0x87, /*!< */
   kNXTHandleAllReadyClosed    = 0x88, /*!< */
   kNXTNoLinearSpace           = 0x89, /*!< */
   kNXTUndefinedError          = 0x8A, /*!< */
   kNXTFileIsBusy              = 0x8B, /*!< */
   kNXTNoWriteBuffers          = 0x8C, /*!< */
   kNXTAppendNotPossible       = 0x8D, /*!< */
   kNXTFileIsFull              = 0x8E, /*!< */
   kNXTFileExists              = 0x8F, /*!< */
   kNXTModuleNotFound          = 0x90, /*!< */
   kNXTOutOfBoundary           = 0x91, /*!< */
   kNXTIllegalFileName         = 0x92, /*!< */
   kNXTIllegalHandle           = 0x93, /*!< */
   kNXTRequestFailed           = 0xBD, /*!< */
   kNXTUnknownOpCode           = 0xBE, /*!< */
   kNXTInsanePacket            = 0xBF, /*!< */
   kNXTOutOfRange              = 0xC0, /*!< */
   kNXTBusError                = 0xDD, /*!< */
   kNXTCommunicationOverflow   = 0xDE, /*!< */
   kNXTChanelInvalid           = 0xDF, /*!< */
   kNXTChanelBusy              = 0xE0, /*!< */
   kNXTNoActiveProgram         = 0xEC, /*!< */
   kNXTIllegalSize             = 0xED, /*!< */
   kNXTIllegalMailbox          = 0xEE, /*!< */
   kNXTInvalidField            = 0xEF, /*!< */
   kNXTBadInputOutput          = 0xF0, /*!< */
   kNXTInsufficientMemmory     = 0xFB, /*!< */
   kNXTBadArguments            = 0xFF  /*!< */
};

/* FileSystem Write types */
enum {
   kNXTRead=0x00,
   kNXTAppend=0x01,
   kNXTWrite=0x02,
   kNXTWriteLinear = 0x03,
   kNXTWriteLinearData = 0x04   
};

/* These are Advanced commands for file system access and other low level commands */
enum {
   kNXT_SYS_OPEN_READ                = 0x80,
   kNXT_SYS_OPEN_WRITE               = 0x81,
   kNXT_SYS_READ                     = 0x82,
   kNXT_SYS_WRITE                    = 0x83,
   kNXT_SYS_CLOSE                    = 0x84,
   kNXT_SYS_DELETE                   = 0x85,
   kNXT_SYS_FIND_FIRST               = 0x86,
   kNXT_SYS_FIND_NEXT                = 0x87,
   kNXT_SYS_GET_FIRMWARE_VERSION     = 0x88,
   kNXT_SYS_OPEN_WRITE_LINEAR        = 0x89,
   kNXT_SYS_OPEN_READ_LINEAR         = 0x8A,
   kNXT_SYS_OPEN_WRITE_DATA          = 0x8B,
   kNXT_SYS_OPEN_APPEND_DATA         = 0x8C,
   kNXT_SYS_BOOT                     = 0x97,
   kNXT_SYS_SET_BRICK_NAME           = 0x98,
   kNXT_SYS_GET_DEVICE_INFO          = 0x9B,
   kNXT_SYS_DELETE_USER_FLASH        = 0xA0,
   kNXT_SYS_POLL_COMMAND_LENGTH      = 0xA1,
   kNXT_SYS_POLL_COMMAND             = 0xA2,
   kNXT_SYS_BLUETOOTH_FACTORY_RESET  = 0xA4
};

#define NXT_ASSERT_SENSOR_PORT(port) NSAssert1( port <= kNXTSensor4, @"invalid sensor port: %d", port);
#define NXT_ASSERT_MOTOR_PORT(port)  NSAssert1( port <= kNXTMotorC || port == kNXTMotorAll, @"invalid servo port: %d", port);

