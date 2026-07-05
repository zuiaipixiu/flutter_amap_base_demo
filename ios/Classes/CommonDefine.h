//
//  CommonDefine.h
//  TFBase
//
//  Created by tengfei on 2019/6/12.
//  Copyright © 2019 tengfei. All rights reserved.
//

#ifndef CommonDefine_h
#define CommonDefine_h

// Include any system framework and library headers here that should be included in all compilation units.
// You will also need to set the Prefix Header build setting of one or more of your targets to reference this file.
/** 获取APP名称 */

#define APP_NAME ([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"])
#define AppDelegate_Tool     ((AppDelegate *)[[UIApplication sharedApplication] delegate])
//----------------------系统设备相关----------------------------
//获取设备屏幕尺寸
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)//应用尺寸
#define APP_WIDTH [[UIScreen mainScreen]applicationFrame].size.width
#define APP_HEIGHT [[UIScreen mainScreen]applicationFrame].size.height
//获取系统版本
#define IOS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]
#define CurrentSystemVersion [[UIDevice currentDevice] systemVersion]
#define isIOS11 ([[[UIDevice currentDevice] systemVersion] intValue]==11)
#define isIOS12 ([[[UIDevice currentDevice] systemVersion] intValue]==12)
#define isAfterIOS11 ([[[UIDevice currentDevice] systemVersion] intValue]>11)
//获取当前语言
#define CurrentLanguage ([[NSLocale preferredLanguages] objectAtIndex:0])

//获取通知中心
#define LRNotificationCenter [NSNotificationCenter defaultCenter]

//获取相关高度
#define TY_StatusBarHeight          \
[[UIApplication sharedApplication] statusBarFrame].size.height  //状态栏高度
#define TY_NavBarHeight 44.0                                        //NavBar高度
#define TY_TabBarHeight (TY_StatusBarHeight > 20 ? 83 : 49)         //底部tabbar高度
#define TY_NavTopHeight (TY_StatusBarHeight + TY_NavBarHeight)      //整个导航栏高度

//判断是真机还是模拟器
#if TARGET_OS_IPHONE
//iPhone Device
#endif

#if TARGET_IPHONE_SIMULATOR
//iPhone Simulator
#endif
 


//---------------------打印日志--------------------------
//Debug模式下打印日志,当前行,函数名
#if DEBUG
#define DLog(FORMAT, ...) nil

//#define DLog(FORMAT, ...) fprintf(stderr,"\n%s[L:%d]:%s\n", __FUNCTION__, __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);

#else

#define DLog(FORMAT, ...) nil

#endif

//打印Frame
#define LogFrame(frame) NSLog(@"frame[X=%.1f,Y=%.1f,W=%.1f,H=%.1f",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height)
//打印Point
#define LogPoint(point) NSLog(@"Point[X=%.1f,Y=%.1f]",point.x,point.y)
//---------------------打印日志--------------------------

//---------------------视图控制--------------------------
#define kWindow [UIApplication sharedApplication].keyWindow

//设置 view 圆角和边框
#define LRViewBorderRadius(View, Radius, Width, Color)\
\
[View.layer setCornerRadius:(Radius)];\
[View.layer setMasksToBounds:YES];\
[View.layer setBorderWidth:(Width)];\
[View.layer setBorderColor:[Color CGColor]]

#define LRToast(str)              CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle]; \
[kWindow  makeToast:str duration:0.6 position:CSToastPositionCenter style:style];\
kWindow.userInteractionEnabled = NO; \
dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{\
kWindow.userInteractionEnabled = YES;\
});\

#define iOSFontWithPx(px)       (px/(96/72))
#define iOSMarginWithPx(px)     ((SCREEN_WIDTH > 375 || SCREEN_HEIGHT > 667) ? px / 3 : px / 2)




//判断手机型号

//判断是否是ipad

#define isPad ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

// iPhone4S

#define IS_iPhone_4S ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640,960), [[UIScreen mainScreen] currentMode].size) : NO)

// iPhone5 iPhone5s iPhoneSE

#define IS_iPhone_5 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640,1136), [[UIScreen mainScreen] currentMode].size) : NO)

// iPhone6 7 8

#define IS_iPhone_6 ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(750,1334), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(640,1136), [[UIScreen mainScreen] currentMode].size)) : NO)

// iPhone6plus  iPhone7plus iPhone8plus

#define IS_iPhone6_Plus ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? (CGSizeEqualToSize(CGSizeMake(1125,2001), [[UIScreen mainScreen] currentMode].size) || CGSizeEqualToSize(CGSizeMake(1242,2208), [[UIScreen mainScreen] currentMode].size)) : NO)

// iPhoneX.iPHoneXs

#define IS_iPhoneX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125,2436), [[UIScreen mainScreen] currentMode].size) : NO)

//判断iPHoneXr

#define IS_iPhoneXR ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828,1792), [[UIScreen mainScreen] currentMode].size) : NO)

//判断iPhoneXs Max

#define IS_iPhoneXS_MAX ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242,2688), [[UIScreen mainScreen] currentMode].size) : NO)


 

#endif /* CommonDefine_h */
