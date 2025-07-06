#import "GoogleMapQOSManager.h"

@interface GoogleMapQOSManager ()
@property (nonatomic, strong) dispatch_queue_t mapQueue;
@property (nonatomic, strong) dispatch_queue_t backgroundQueue;
@end

@implementation GoogleMapQOSManager

+ (instancetype)sharedInstance {
    static GoogleMapQOSManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[GoogleMapQOSManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create serial queue for map operations with high QoS
        self.mapQueue = dispatch_queue_create("com.artbeat.maps.operations", 
                                            dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, 
                                                                                  QOS_CLASS_USER_INTERACTIVE, 0));
        
        // Create background queue for non-critical operations
        self.backgroundQueue = dispatch_queue_create("com.artbeat.maps.background", 
                                                   dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, 
                                                                                         QOS_CLASS_UTILITY, 0));
    }
    return self;
}

- (void)initializeMapServicesWithCompletion:(void (^)(void))completion {
    dispatch_async(self.backgroundQueue, ^{
        // Initialize Google Maps services on background thread
        [GMSServices sharedServices];
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), completion);
        }
    });
}

- (void)performMapOperation:(void (^)(void))operation {
    if (!operation) return;
    
    dispatch_async(self.mapQueue, ^{
        @autoreleasepool {
            operation();
        }
    });
}

- (void)performBackgroundMapOperation:(void (^)(void))operation {
    if (!operation) return;
    
    dispatch_async(self.backgroundQueue, ^{
        @autoreleasepool {
            operation();
        }
    });
}

@end
