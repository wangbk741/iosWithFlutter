//
//  ViewController.m
//  FlutterMix
//
//  Created by apple1 on 2020/4/22.
//  Copyright © 2020 apple1. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <Flutter/Flutter.h>
@import Flutter;

@interface ViewController (){
    FlutterEventSink _eventSink;
    
}
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
}
-(void)viewWillAppear:(BOOL)animated
{
    if (self.value.length!=0) {
        [_btn setTitle:[NSString stringWithFormat:@"%@",self.value] forState:UIControlStateNormal];
    }
}
- (IBAction)toFlutter:(id)sender {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    FlutterEngine *flutterEngine =
        ((AppDelegate *)UIApplication.sharedApplication.delegate).flutterEngine;
    FlutterViewController *controller =
        [[FlutterViewController alloc] initWithEngine:flutterEngine nibName:nil bundle:nil];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:controller animated:YES completion:nil];
    
    FlutterMethodChannel* batteryChannel = [FlutterMethodChannel
        methodChannelWithName:@"samples.flutter.io/battery"
              binaryMessenger:controller];
    __weak typeof(self) weakSelf = self;
    [batteryChannel setMethodCallHandler:^(FlutterMethodCall* call,
                                           FlutterResult result) {
      if ([@"getBatteryLevel" isEqualToString:call.method]) {
        int batteryLevel = [weakSelf getBatteryLevel];
        if (batteryLevel == -1) {
          result([FlutterError errorWithCode:@"UNAVAILABLE"
                                     message:@"Battery info unavailable"
                                     details:nil]);
        } else {
          result(@(batteryLevel));
        }
      } else if([@"passCounter" isEqualToString:call.method]){
          __strong __typeof(weakSelf) strongSelf = weakSelf;
//          NSLog(@"%@",call.arguments);
          strongSelf->_value = [NSString stringWithFormat:@"%@", call.arguments];
      } else {
        result(FlutterMethodNotImplemented);
      }
    }];

    FlutterEventChannel* chargingChannel = [FlutterEventChannel
        eventChannelWithName:@"samples.flutter.io/charging"
             binaryMessenger:controller];
    [chargingChannel setStreamHandler:self];
}
- (int)getBatteryLevel {
  UIDevice* device = UIDevice.currentDevice;
  device.batteryMonitoringEnabled = YES;
  if (device.batteryState == UIDeviceBatteryStateUnknown) {
    return -1;
  } else {
    return ((int)(device.batteryLevel * 100));
  }
}

- (FlutterError*)onListenWithArguments:(id)arguments
                             eventSink:(FlutterEventSink)eventSink {
  _eventSink = eventSink;
  [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
  [self sendBatteryStateEvent];
  [[NSNotificationCenter defaultCenter]
   addObserver:self
      selector:@selector(onBatteryStateDidChange:)
          name:UIDeviceBatteryStateDidChangeNotification
        object:nil];
  return nil;
}

- (void)onBatteryStateDidChange:(NSNotification*)notification {
  [self sendBatteryStateEvent];
}

- (void)sendBatteryStateEvent {
  if (!_eventSink) return;
  UIDeviceBatteryState state = [[UIDevice currentDevice] batteryState];
  switch (state) {
    case UIDeviceBatteryStateFull:
    case UIDeviceBatteryStateCharging:
      _eventSink(@"charging");
      break;
    case UIDeviceBatteryStateUnplugged:
      _eventSink(@"discharging");
      break;
    default:
      _eventSink([FlutterError errorWithCode:@"UNAVAILABLE"
                                     message:@"Charging status unavailable"
                                     details:nil]);
      break;
  }
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  _eventSink = nil;
  return nil;
}

@end
