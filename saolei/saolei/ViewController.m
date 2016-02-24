//
//  ViewController.m
//  saolei
//
//  Created by 周文涛 on 16/1/14.
//  Copyright © 2016年 周文涛. All rights reserved.
//

#import "ViewController.h"

#define SCREENW ([UIScreen mainScreen].bounds.size.width - 1)
#define SCREENH ([UIScreen mainScreen].bounds.size.height)

//手势类型 controller
typedef NS_ENUM(NSInteger, TapType) {
    TapTypeNone = 0,                //复原
    TapTypeLook,                    //查看
    TapTypeRedFlag,                 //地雷
    TapTypeUnknow                   //未知
};

//单元格样式 view
typedef NS_ENUM(NSInteger, CellType) {
    CellTypeNormal = 11,            //正常状态
    CellTypeRedFlag,                //小红旗
    CellTypeUnknow,                 //问号
    CellTypeMine,                   //地雷
    CellTypeGray,                   //灰色
};

//地雷数据样式
typedef NS_ENUM(NSInteger, SourceModel) {
    SourceModelNone = 11,           //什么都没有
    SourceModelMine = 12,           //地雷
};


//选取器
struct ArrIJ {
    int i;
    int j;
};
typedef struct ArrIJ ArrIJ;
CG_INLINE ArrIJ
ArrIJMake(int i, int j)
{
    ArrIJ a; a.i = i; a.j = j; return a;
}




/***********************************/

@interface ViewController ()<UITextFieldDelegate>

{
    float width;
    int mines[9][9];            //地雷数据
    int UIMines[9][9];          //雷区UI样式
    int tapGrapCount;           //灰色个数
    UIView * minesScreen;       //雷区
    UITapGestureRecognizer * tap;
    
    TapType tapType;            //点击方式
    UISegmentedControl * segment;//分栏
    
    int nowTime;                //时间
    NSTimer * timer;            //计时器

    UILabel * timesLabel;       //时间
    UILabel * titleLabel;       //标题
    UIButton * resetBtn;        //重新开始按钮
    UIButton * sleepBtn;        //暂停按钮
    UILabel * overLabel;        //结束
    
}

@end

@implementation ViewController

- (void)DoubleForCirculate:(void(^)(int i,int j))block
{
    for (int i = 0; i < 9; i++) {
        for (int j = 0; j < 9; j++) {
            block(i,j);
        }
    }
}
//- (void)pointUIMines
//{
//    printf("\n\n\n\n");
//    for (int i = 0; i < 9; i++) {
//        for (int j = 0; j < 9; j++) {
//
//            printf("  %3d",UIMines[i][j]);
//        }
//        printf("\n");
//    }
//}

- (void)viewDidLoad {
    [super viewDidLoad];
    width = SCREENW/9.0f;
    tapType = TapTypeLook;
    [self buildSaoleiData];
    [self createMineScreen];
    [self createOtherUI];
}

- (void)buildSaoleiData
{
    tapGrapCount = 0;
    [self createMineScreenSource];
    [self buildMines];
    [self buildNumbs];
}

#pragma mark 部署扫雷基本数据
//创建扫雷地雷数据，展示数据
- (void)createMineScreenSource
{
    [self DoubleForCirculate:^(int i, int j) {
        mines[i][j] = SourceModelNone;
        UIMines[i][j] = CellTypeNormal;
    }];
}

//布雷
- (void)buildMines
{
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    
    MineCount = 20;
    if ([defaults objectForKey:@"MINES_MAX_COUNT"]) {
        MineCount = [[defaults objectForKey:@"MINES_MAX_COUNT"] intValue];
    }
    int minesCount = 0;
    while (minesCount < MineCount) {
        int i_index = arc4random()%9;
        int j_index = arc4random()%9;
        if (mines[i_index][j_index] == SourceModelNone) {
            mines[i_index][j_index] = SourceModelMine;
            minesCount++;
        }
    }
}

//填充数字
- (void)buildNumbs
{
    [self DoubleForCirculate:^(int i, int j) {
        if (mines[i][j] != SourceModelMine) {
            int mineCount = [self seekNearbyMines:ArrIJMake(i, j)];
            if (mineCount) {
                mines[i][j] = mineCount;
            }
        }
    }];
}

#pragma mark 扫雷阵地
//创建雷阵UI
- (void)createMineScreen
{
    minesScreen = [[UIView alloc]initWithFrame:CGRectMake(0, 100, SCREENW+1, SCREENW+1)];
    minesScreen.backgroundColor = [UIColor blackColor];
    [self.view addSubview:minesScreen];
    
    [self DoubleForCirculate:^(int i, int j) {
        UILabel * label= [[UILabel alloc]initWithFrame:CGRectMake(j*width+1, i*width+1, width-1, width-1)];
        label.tag = 100+i*10+j;
        label.backgroundColor = [UIColor whiteColor];
        label.textAlignment =  NSTextAlignmentCenter;
        [minesScreen addSubview:label];
    }];
    [self addtap];
}

- (void)addtap
{
    tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapInMinesScreen:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [minesScreen addGestureRecognizer:tap];
}

#pragma mark - 检索
//查找附近地雷
- (int)seekNearbyMines:(ArrIJ)arrIJ
{
    int mineCount = 0;
    for (int i = MAX(0, arrIJ.i - 1); i <= MIN(8, arrIJ.i + 1); i++) {
        for (int j = MAX(0, arrIJ.j - 1); j <= MIN(8, arrIJ.j + 1); j++) {
            if (mines[i][j] == SourceModelMine) {
                mineCount++;
            }
        }
    }
    return mineCount;
}

//查找附近灰色地区
- (void)seekNearbyNone:(ArrIJ)arrIJ
{
    for (int i = MAX(0, arrIJ.i - 1); i <= MIN(8, arrIJ.i + 1); i++) {
        for (int j = MAX(0, arrIJ.j - 1); j <= MIN(8, arrIJ.j + 1); j++) {
            if (i-arrIJ.i == j-arrIJ.j) {
                continue;
            }else if (i+j == arrIJ.i+arrIJ.j){
                continue;
            }
            if (UIMines[i][j] == CellTypeNormal && mines[i][j] == SourceModelNone) {//上
                [self setNoneViewArrIJ:ArrIJMake(i, j)];
            }
            if (UIMines[i][j] == CellTypeNormal && mines[i][j] != SourceModelMine) {//上
                [self setNumbViewArrIJ:ArrIJMake(i, j) count:mines[i][j]];
            }
        }
    }
}

#pragma mark - 改变雷阵状态
//设置数字
- (void)setNumbViewArrIJ:(ArrIJ)arrIJ count:(int)count
{
    UIMines[arrIJ.i][arrIJ.j] = count;
    UILabel * label = (UILabel *)[minesScreen viewWithTag:100+10*arrIJ.i+arrIJ.j];
    label.backgroundColor = [UIColor grayColor];
    label.text = [NSString stringWithFormat:@"%d",count];
    tapGrapCount++;
    if (tapGrapCount == 81-MineCount) {
        [self survive];
        return;
    }
    //[self pointUIMines];
}

//设置Gray
- (void)setNoneViewArrIJ:(ArrIJ)arrIJ
{
    UIMines[arrIJ.i][arrIJ.j] = CellTypeGray;
    UIView * view = [minesScreen viewWithTag:100+10*arrIJ.i+arrIJ.j];
    view.backgroundColor = [UIColor grayColor];
    tapGrapCount++;
    NSLog(@"%d",tapGrapCount);
    if (tapGrapCount == 81-MineCount) {
        [self survive];
        return;
    }
    [self seekNearbyNone:arrIJ];
}

//设置红旗、问号、普通
- (void)setViewType:(CellType)type arrIJ:(ArrIJ)arrIJ
{
    if (UIMines[arrIJ.i][arrIJ.j] == CellTypeGray || UIMines[arrIJ.i][arrIJ.j] < 10) {
        return;
    }
    UIMines[arrIJ.i][arrIJ.j] = type;
    UIView * view = [minesScreen viewWithTag:100+10*arrIJ.i+arrIJ.j];
    switch (type) {
        case CellTypeNormal:        //普通
            view.backgroundColor = [UIColor whiteColor];
            break;
        case CellTypeRedFlag:       //红旗
            view.backgroundColor = [UIColor greenColor];
            break;
        default:                    //问号
            view.backgroundColor = [UIColor blueColor];
            break;
    }
}

- (void)judgeViewArrIJ:(ArrIJ)arrIJ
{
    if (mines[arrIJ.i][arrIJ.j] == SourceModelNone) {               //空的
        [self setNoneViewArrIJ:arrIJ];
    }else if (mines[arrIJ.i][arrIJ.j] == SourceModelMine){          //地雷
        [self boom];
    }else{                                                          //数字
        [self setNumbViewArrIJ:arrIJ count:mines[arrIJ.i][arrIJ.j]];
    }
}

//查看单元格
- (void)cellTap:(ArrIJ)arrIJ
{
    switch (tapType) {
        case TapTypeNone://复原
            [self setViewType:CellTypeNormal arrIJ:arrIJ];
            break;
        case TapTypeLook://查看
            [self judgeViewArrIJ:arrIJ];
            break;
        case TapTypeRedFlag://红旗
            [self setViewType:CellTypeRedFlag arrIJ:arrIJ];
            break;
        default://未知
            [self setViewType:CellTypeUnknow arrIJ:arrIJ];
            break;
    }
}
#pragma 手势
//扫雷
- (void)tapInMinesScreen:(UITapGestureRecognizer *)tapg
{
    CGPoint point = [tapg locationInView:minesScreen];
    ArrIJ arrIJ = ArrIJMake(point.y/width, point.x/width);
    //NSLog(@"%d",UIMines[arrIJ.i][arrIJ.j]);
    if (UIMines[arrIJ.i][arrIJ.j] != CellTypeGray) {
        [self cellTap:arrIJ];
    }
}

//扫尾
- (void)over:(NSString *)over
{
    if (!overLabel) {
        overLabel = [[UILabel alloc]init];
        overLabel.bounds = CGRectMake(0, 0, 150, 100);
        overLabel.center = minesScreen.center;
        overLabel.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
        overLabel.textAlignment = NSTextAlignmentCenter;
        overLabel.font = [UIFont systemFontOfSize:20];
        overLabel.textColor = [UIColor orangeColor];
    }
    overLabel.text = over;
    [self.view addSubview:overLabel];
    [timer invalidate];
    timer = nil;
    [minesScreen removeGestureRecognizer:tap];
    tap = nil;
}

//game over
- (void)boom
{
    [self DoubleForCirculate:^(int i, int j) {
        if (mines[i][j] == SourceModelMine && UIMines[i][j] != CellTypeRedFlag) {
            UIView * view = [minesScreen viewWithTag:100+10*i+j];
            view.backgroundColor = [UIColor redColor];
        }
    }];
    [self over:@"BOOM"];
}
//胜利
- (void)survive
{
    [self over:@"GOOD"];
}

#pragma mark - 次要视图
- (void)createOtherUI
{
    [self createTopLabel];
    [self createTopBtn];
    [self createSegmentControl];
    [self createTextField];
    [self buildOtherInfo];
}

- (void)createTopLabel
{
    timesLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREENW/2-25, 60, 50, 15)];
    timesLabel.textAlignment = NSTextAlignmentCenter;
    timesLabel.font = [UIFont systemFontOfSize:13];
    timesLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1];
    [self.view addSubview:timesLabel];
    
    titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(SCREENW/2-25, 30, 50, 30)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.text = @"扫雷";
    [self.view addSubview:titleLabel];
}

- (void)createTopBtn
{
    resetBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [resetBtn setTitle:@"重玩" forState:UIControlStateNormal];
    [resetBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    resetBtn.frame = CGRectMake(10, 30 , 55, 44);
    [self.view addSubview:resetBtn];
    [resetBtn addTarget:self action:@selector(pressResetBtn) forControlEvents:UIControlEventTouchUpInside];
    
    sleepBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [sleepBtn setTitle:@"暂停" forState:UIControlStateNormal];
    [sleepBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    sleepBtn.frame = CGRectMake(SCREENW-65, 30, 55, 44);
    [self.view addSubview:sleepBtn];
    [sleepBtn addTarget:self action:@selector(pressSleepBtn) forControlEvents:UIControlEventTouchUpInside];
}

- (void)createSegmentControl
{
    NSArray * types = @[@"还原",@"查看",@"地雷",@"未知"];
    segment = [[UISegmentedControl alloc]initWithItems:types];
    segment.tintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    segment.frame = CGRectMake(30, 120+SCREENW, SCREENW-60, 30);
    [self.view addSubview:segment];
    [segment addTarget:self action:@selector(ClicksegmentedControlAction:) forControlEvents:UIControlEventValueChanged];
    segment.tintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
}

#pragma mark -  设置地雷个数
- (void)createTextField
{
    UITextField * textField = [[UITextField alloc]initWithFrame:CGRectMake(0, SCREENH-40, SCREENW+1, 40)];
    textField.backgroundColor = [UIColor colorWithWhite:0.94 alpha:1];
    [self.view addSubview:textField];
    textField.tag = 666;
    textField.delegate = self;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    textField.transform = CGAffineTransformMakeTranslation(0, -290);
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    textField.transform = CGAffineTransformIdentity;
    NSUserDefaults * defaults = [NSUserDefaults standardUserDefaults];
    int num = [textField.text intValue];
    int count = MAX(MIN(num, 30), 1);
    [defaults setObject:[NSString stringWithFormat:@"%d",count] forKey:@"MINES_MAX_COUNT"];
    textField.text = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - 次要数据

- (void)buildOtherInfo
{
    nowTime = 0;
    timesLabel.text = @"0";
    segment.selectedSegmentIndex = tapType;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(SleepTime) userInfo:nil repeats:YES];
}

- (void)SleepTime
{
    nowTime++;
    timesLabel.text = [NSString stringWithFormat:@"%d",nowTime];
}

#pragma mark - UIController
- (void)pressResetBtn
{
    [self resetUI];
    [self buildSaoleiData];
}

- (void)resetUI{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
    if (overLabel.superview) {
        [overLabel removeFromSuperview];
    }
    
    [self DoubleForCirculate:^(int i, int j) {
        UILabel * label= (UILabel *)[minesScreen viewWithTag:100+i*10+j];
        label.backgroundColor = [UIColor whiteColor];
        label.text = @"";
    }];
    [self buildOtherInfo];
    [self addtap];

}

- (void)pressSleepBtn
{
    static BOOL sleep = NO;
    sleep = !sleep;
    if (sleep) {
        [timer setFireDate:[NSDate distantFuture]];
        [sleepBtn setTitle:@"继续" forState:UIControlStateNormal];
    }else{
        [timer setFireDate:[NSDate date]];
        [sleepBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
}

- (void)ClicksegmentedControlAction:(UISegmentedControl *)Seg
{
    tapType = segment.selectedSegmentIndex;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end


