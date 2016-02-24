//
//  ViewController.m
//  landun
//
//  Created by 周文涛 on 16/1/19.
//  Copyright © 2016年 周文涛. All rights reserved.
//

#import "ViewController.h"

/*! 屏幕宽高 */
#define SCREENWIDTH   [UIScreen mainScreen].bounds.size.width

#define SCREENHEIGHT  [UIScreen mainScreen].bounds.size.height

#define SH3 3
#define SH4 4

//当前面朝方向
typedef NS_ENUM(int, RunDirection) {
    RunDirectionUp = 0,
    RunDirectionLeft,
    RunDirectionDown,
    RunDirectionRight
};

//向左拐or向右拐
typedef NS_ENUM(int, TurnFirection) {
    TurnFirectionLeft = 0,
    TurnFirectionRight
};


@interface LadAnt : UIView

@property(nonatomic,assign)RunDirection runDir;

@property(nonatomic,assign)TurnFirection turnDir;

@property(nonatomic,assign)CGPoint location;

@end

@implementation LadAnt

- (id)initWithLocation:(CGPoint)location RunDir:(RunDirection)runDir  TurnDir:(TurnFirection)turnDir
{
    self = [super init];
    if (self) {
        self.bounds = CGRectMake(0, 0, SH3, SH3);
        self.center = location;
        self.runDir = runDir;
        self.turnDir = turnDir;
    }
    return self;
}

//- (void)setRunDir:(RunDirection)runDir
//{
//    _runDir = runDir;
////    switch (_runDir) {
////        case RunDirectionUp:
////            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"antUp.png"]];
////            break;
////        case RunDirectionLeft:
////            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"antLeft.png"]];
////            break;
////        case RunDirectionDown:
////            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"antDown.png"]];
////            break;
////        default:
////            self.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"antRight.png"]];
////            break;
////    }
//}

- (void)setLocation:(CGPoint)location
{
    _location = location;
    self.center = location;
}

//绝对位置位移
- (void)running
{
    CGPoint center = self.center;
    switch (_runDir) {
        case RunDirectionUp:
        {
            center.y-=SH4;
            self.center = center;
        }
            break;
        case RunDirectionLeft:
        {
            center.x-=SH4;
            self.center = center;
        }            break;
        case RunDirectionDown:
        {
            center.y+=SH4;
            self.center = center;
        }            break;
        default:
        {
            center.x+=SH4;
            self.center = center;
        }            break;
    }
}

- (void)turnLeft
{
    if (_runDir == RunDirectionRight) {
        self.runDir = RunDirectionUp;
    }else{
        self.runDir = _runDir+1;
    }
}

- (void)turnRight
{
    if (_runDir == RunDirectionUp) {
        self.runDir = RunDirectionRight;
    }else{
        self.runDir = _runDir-1;
    }
}

@end


@interface ViewController ()

{
    LadAnt * ant1;
    LadAnt * ant2;
    LadAnt * ant3;
    LadAnt * ant4;
    NSMutableArray * ants;
    NSTimer * timer;            //计时器
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    [self createGrid];
    [self createAnts];
    [self createTestBtn];
}

- (void)createGrid
{
    self.view.backgroundColor = [UIColor grayColor];
    for (int i = 0; i <= SCREENWIDTH; i+=SH4) {
        for (int j = 0; j <= SCREENHEIGHT; j+=SH4) {
            UIView * view = [[UIView alloc]initWithFrame:CGRectMake(i, j, SH3, SH3)];
            view.tag = view.center.x * 1000 + view.center.y;
            view.backgroundColor = [UIColor whiteColor];
            [self.view addSubview:view];
        }
    }
}

- (void)createAnts
{
    int xx = SCREENWIDTH/2/SH4;
    int yy = SCREENHEIGHT/2/SH4;
    ants = [[NSMutableArray alloc]init];
    
    
    ant1 = [[LadAnt alloc]initWithLocation:CGPointMake((xx-15)*SH4+1.5, (yy-15)*SH4+1.5) RunDir:RunDirectionUp TurnDir:TurnFirectionLeft];
    ant1.backgroundColor = [UIColor orangeColor];
    [ants addObject:ant1];

    ant2 = [[LadAnt alloc]initWithLocation:CGPointMake((xx+15)*SH4+1.5, (yy-15)*SH4+1.5) RunDir:RunDirectionUp TurnDir:TurnFirectionLeft];
    ant2.backgroundColor = [UIColor brownColor];
    [ants addObject:ant2];

    ant3 = [[LadAnt alloc]initWithLocation:CGPointMake((xx-15)*SH4+1.5, (yy+15)*SH4+1.5) RunDir:RunDirectionDown TurnDir:TurnFirectionLeft];
    ant3.backgroundColor = [UIColor cyanColor];
    [ants addObject:ant3];

    ant4 = [[LadAnt alloc]initWithLocation:CGPointMake((xx+15)*SH4+1.5, (yy+15)*SH4+1.5) RunDir:RunDirectionDown TurnDir:TurnFirectionLeft];
    ant4.backgroundColor = [UIColor blueColor];
    [ants addObject:ant4];
    
    for (LadAnt * ant in ants) {
        [self.view addSubview:ant];
    }
}

- (void)AntsRunning
{
    for (LadAnt * ant in ants) {
        CGPoint antCenter = ant.center;
        UIView * view = [self.view viewWithTag:antCenter.x*1000+antCenter.y];
        if ([view.backgroundColor isEqual:[UIColor whiteColor]]) {
            
            if (ant.turnDir == TurnFirectionLeft) {
                [ant turnLeft];
            }else{
                [ant turnRight];
            }
            [ant running];
            view.backgroundColor = [UIColor blackColor];

        }else{
            
            if (ant.turnDir == TurnFirectionLeft) {
                [ant turnRight];
            }else{
                [ant turnLeft];
            }
            [ant running];
            view.backgroundColor = [UIColor whiteColor];
        }
    }
}

- (void)createTestBtn
{
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.frame = CGRectMake(SCREENWIDTH-30, SCREENHEIGHT-30, 30, 30);
    btn.backgroundColor = [UIColor redColor];
    [btn addTarget:self action:@selector(pressbtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];

}

- (void)pressbtn:(UIButton *)sleepBtn
{
    if (!timer) {
        timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(AntsRunning) userInfo:nil repeats:YES];
    }
    
    static BOOL sleep = YES;
    sleep = !sleep;
    if (sleep) {
        [timer setFireDate:[NSDate distantFuture]];
        sleepBtn.backgroundColor = [UIColor redColor];
    }else{
        [timer setFireDate:[NSDate date]];
        sleepBtn.backgroundColor = [UIColor greenColor];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
