#import "panoramaUIView.h"
#import <CoreMotion/CoreMotion.h>

//宏定义: 屏幕的Height 和 Width
#define SCREEN_H [UIScreen mainScreen].bounds.size.height
#define SCREEN_W [UIScreen mainScreen].bounds.size.width

@interface panoramaUIView ()

@property (nonatomic, strong) UIScrollView    *panoramaView;     //显示全景的 ScrollView
@property (nonatomic, strong) CMMotionManager *manager;          //运动检测的变量
@property (nonatomic, assign) CGSize          CorrectedPhotoSize;//修正后的图片宽和高(填充横竖屏)
@property (nonatomic, strong) UIImage         *leftPhoto;        //真正的左图
@property (nonatomic, strong) UIImage         *middlePhoto;      //真正的中图
@property (nonatomic, strong) UIImage         *rightPhoto;       //真正的右图
@property (nonatomic, strong) NSMutableArray  *photoArray;       //包含五图的图片数组

@end



@implementation panoramaUIView


#pragma mark 初始化
/*  逻辑:
    1. 创建自身类的实例
    2. 创建ScrollView 和 ImageView, 并设置 ScrollView 显示图片的初始位置
    3. 启动运动传感器, 转换图片的的显示位置给 ScrollView
 */
- (instancetype) initWithPhoto: (NSString *) photoName {
    
    //创建自身类的实例
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    self = [[panoramaUIView alloc] initWithFrame:screenRect];
    
    //根据接收的图片关键名称合成图片名, 指定图片, 完成五图数组
    self.leftPhoto   = [UIImage imageNamed:[photoName stringByAppendingString:@" left"  ]];
    self.middlePhoto = [UIImage imageNamed:[photoName stringByAppendingString:@" middle"]];
    self.rightPhoto  = [UIImage imageNamed:[photoName stringByAppendingString:@" right" ]];
    
    self.photoArray = [NSMutableArray new];
    [self.photoArray addObject: self.rightPhoto ];
    [self.photoArray addObject: self.leftPhoto  ];
    [self.photoArray addObject: self.middlePhoto];
    [self.photoArray addObject: self.rightPhoto ];
    [self.photoArray addObject: self.leftPhoto  ];

    
    //添加全景 view 和图片 view
    [self addScrollView];
    [self addImageView ];
    
    
    //设定 全景 view 显示图片的初始位置
    self.panoramaView.contentSize   = CGSizeMake (self.CorrectedPhotoSize.width * 5,
                                                  self.CorrectedPhotoSize.height);
    
    self.panoramaView.contentOffset = CGPointMake(self.CorrectedPhotoSize.width * 2, 0);
    
    
    //设置设备运动传感器,获取数据,转化成图片要移动到的位置
    [self startGyroUpdates];
    
    return self;
}


//实现添加ScrollView 的方法
- (void) addScrollView {
    
    self.panoramaView                 = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.panoramaView.backgroundColor = [UIColor blueColor];
    self.panoramaView.scrollEnabled   = YES; //允许触屏操作
    
    [self addSubview:self.panoramaView];
}


#pragma mark 添加图片视图的方法
/*  逻辑:
    1. 获取图片尺寸, 转换为与屏幕适配后的尺寸
    2. 建立右,左,中,右,左五个显示图片的 ImageView
 */
- (void) addImageView {

    CGSize originalPhotoSize = self.middlePhoto.size;
    
    //横竖屏都需要图片的 Height 填满屏幕
    float newWidth = originalPhotoSize.width / originalPhotoSize.height * SCREEN_H;
    self.CorrectedPhotoSize = CGSizeMake(newWidth, SCREEN_H);
    
    //依次添加图片 View
    CGFloat imageX = 0;
    CGFloat imageY = 0;
    CGFloat imageW = self.CorrectedPhotoSize.width ;
    CGFloat imageH = self.CorrectedPhotoSize.height;
    
    for (int imageIndex = 0; imageIndex < 5; imageIndex ++) {
        
        UIImageView *imageView = [UIImageView new];
        imageX = imageIndex * imageW; //每次都用累加的 x 坐标
        imageView.frame = CGRectMake(imageX, imageY, imageW, imageH);
        imageView.image = self.photoArray[imageIndex];
        
        [self.panoramaView addSubview: imageView];
    }
}


#pragma mark 实现启动运动传感器进行监测的方法
- (void) startGyroUpdates {
    
    self.manager = [CMMotionManager new];
    
    //设定更新频率(可以自定义)
    self.manager.gyroUpdateInterval = 0.01;
    
    //开始监测, 调用方法传递值给 ScrollView 的 ContentOffset, 实现图片位置变动
    if (self.manager.gyroAvailable) {
        [self.manager startGyroUpdatesToQueue:[NSOperationQueue mainQueue]
                                  withHandler:^(CMGyroData * _Nullable gyroData,
                                                NSError * _Nullable error)
        {
            [self updateContentOffset:gyroData];
        }];
    } else {
        NSLog(@"Gyro is not available.");
    }
}


#pragma mark 实现改变图片位置的方法
/*  逻辑:
    1. 判断屏幕横竖
    2. 获取陀螺仪的data, 判断是否是 y 轴方向的运动
    3. 设定暗中更改 ContentOffset 的临界点
    4. 根据设置的合适的参数, 计算出 contentOffset 的值
 */
- (void) updateContentOffset: (CMGyroData*)gyroData {
    
    float xRotationRate = gyroData.rotationRate.x;
    float yRotationRate = gyroData.rotationRate.y;
    float zRotationRate = gyroData.rotationRate.z;
    
    float rotationMultiplier = 5.0; //转动幅度灵敏度(可以自定义,越大转动幅度越大)
    
    if (SCREEN_H < SCREEN_W) //横屏时
    {
        if (fabsf(xRotationRate) > fabsf(yRotationRate) + fabsf(zRotationRate)) {
            
            float invertedXRotationRate = xRotationRate * (-1.0);

            float newXoffset = self.panoramaView.contentOffset.x +
                               invertedXRotationRate * rotationMultiplier;
            
            if (newXoffset <= self.CorrectedPhotoSize.width) {
                newXoffset = self.CorrectedPhotoSize.width * 4 - 0.001;
                
            } else
            if (newXoffset >= self.CorrectedPhotoSize.width * 4){
                newXoffset = self.CorrectedPhotoSize.width + 0.001;
            }
            
            [self.panoramaView setContentOffset:CGPointMake(newXoffset, 0)];
        }
    } else { //竖屏时
        
        if (fabsf(yRotationRate) > fabsf(xRotationRate) + fabsf(zRotationRate)) {
            
            float invertedYRotationRate = yRotationRate * (-1.0);
            
            float newXoffset = self.panoramaView.contentOffset.x +
                               invertedYRotationRate * rotationMultiplier;

            if (newXoffset <= self.CorrectedPhotoSize.width) {
                newXoffset = self.CorrectedPhotoSize.width * 4 - 0.001;
                
            } else
            if (newXoffset >= self.CorrectedPhotoSize.width * 4){
                newXoffset = self.CorrectedPhotoSize.width + 0.001;
            }
            
            [self.panoramaView setContentOffset:CGPointMake(newXoffset, 0)];
        }
    }
}


//实现停止运动监测的方法
- (void) stopUpdate {
    
    if  (self.manager.gyroActive) {
        [self.manager stopGyroUpdates];
    }
}

@end