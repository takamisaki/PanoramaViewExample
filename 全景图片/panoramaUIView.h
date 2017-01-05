#import <UIKit/UIKit.h>

@interface panoramaUIView : UIView

- (instancetype) initWithPhoto: (NSString*)photoName; //输入图片,初始化全景 UIView

- (void) stopUpdate; //停止传感器的检测


@end