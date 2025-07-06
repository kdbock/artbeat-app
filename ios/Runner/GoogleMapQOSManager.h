#ifdef __OBJC__

#ifndef GoogleMapQOSManager_h
#define GoogleMapQOSManager_h

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>
#import <Flutter/Flutter.h>
#import <QuartzCore/QuartzCore.h>
#import <dispatch/dispatch.h>

@class FLTGoogleMapController;
@class GMSCameraUpdate;
@class FGMPlatformCameraUpdate;

NS_ASSUME_NONNULL_BEGIN

@interface GoogleMapQOSManager : NSObject

/**
 * Returns the shared instance of the QOS manager.
 */
+ (instancetype)sharedInstance;

/**
 * Initializes map services on a background queue to avoid blocking the main thread.
 * @param completion Block to be called when initialization is complete.
 */
- (void)initializeMapServicesWithCompletion:(nullable void (^)(void))completion;

/**
 * Executes map operations with proper QoS to prevent priority inversion.
 * @param operation Block containing the map operation to execute.
 */
- (void)performMapOperation:(nonnull void (^)(void))operation;

/**
 * Executes background map operations at utility QoS.
 * @param operation Block containing the background operation to execute.
 */
- (void)performBackgroundMapOperation:(nonnull void (^)(void))operation;

@end

NS_ASSUME_NONNULL_END

#endif /* GoogleMapQOSManager_h */
#endif /* __OBJC__ */
