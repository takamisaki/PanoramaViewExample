#import "ViewController.h"
#import "panoramaUIView.h"

@interface ViewController ()

@property (nonatomic, strong) panoramaUIView *panoramaInstance; //显示全景图的 UIView 实例

@end



@implementation ViewController

- (void) viewDidLoad {

    [super viewDidLoad];
    
    //开启监听屏幕方向
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    //添加屏幕发生旋转时的通知. 这里回调更新全景 View 的方法
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePanoramaUIView)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
}


//屏幕转动时, 更新全景 View
- (void) updatePanoramaUIView {
    
    self.panoramaInstance = [[panoramaUIView alloc] initWithPhoto:@"mario"]; //只需要传入图片关键名称
    
    [self.view addSubview: self.panoramaInstance];
}


//关闭全景图转动
- (void) viewDidDisappear: (BOOL)animated {
    
    [self.panoramaInstance stopUpdate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceOrientationDidChangeNotification
                                                  object:nil];
}

@end
