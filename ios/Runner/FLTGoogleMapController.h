#ifndef FLTGoogleMapController_h
#define FLTGoogleMapController_h

#import <Flutter/Flutter.h>
#import <GoogleMaps/GoogleMaps.h>
#import <QuartzCore/QuartzCore.h>

@class FGMPlatformMapConfiguration;
@class FGMPlatformCameraUpdate;
@class FGMPlatformMarker;

NS_ASSUME_NONNULL_BEGIN

@interface FLTGoogleMapController : NSObject <FlutterPlatformView>

@property(nonatomic, strong, readonly) GMSMapView *mapView;
@property(nonatomic, strong, readonly) id markersController;
@property(nonatomic, strong, readonly) id clusterManagersController;

- (void)interpretMapConfiguration:(FGMPlatformMapConfiguration *)configuration;

@end

NS_ASSUME_NONNULL_END

#endif /* FLTGoogleMapController_h */
