//
//  SmartChartView.m
//  SmartChartView
//
//  Created by Tereshkin Sergey on 02/03/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import "SmartChartView.h"

#define ARROW_UP        7
#define ARROW_RIGHT     8

#define VERT_OFFSET     15.0f
#define TWO             2.0f
#define HUNDRED         100.0f
#define AXIS_WIDTH      1.0f
#define AXIS_FONT_SIZE  15.0f

@interface SmartChartView ()

@property (nonatomic, strong) NSMutableArray *verticalLinesArray;
@property (nonatomic, strong) NSMutableArray *uiViewPointsArray;
@property (nonatomic, strong) NSMutableArray *xAxisLabelsArray;

@property (nonatomic, strong) CAShapeLayer *graphShapedLine;
@property (nonatomic) BOOL isConnectingDots;
@property (nonatomic) BOOL redrawing;

@end

@implementation SmartChartView


//##########################################
//###           Alloc/Init               ###
//##########################################
#pragma mark Alloc/Init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self constructChartView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self constructChartView];
    }
    return self;
}
- (id)init
{
    return [self initWithFrame:CGRectZero];
}

- (void)constructChartView
{
    self.clipsToBounds = NO;
    
    self.verticalLineColor =   [UIColor orangeColor];
    self.horizontalLineColor = [UIColor orangeColor];
    self.graphLineColor =      [UIColor blueColor];
    self.axisColor =           [UIColor redColor];
    self.verticalLinesArray =  [[NSMutableArray alloc]init];
    self.uiViewPointsArray =   [[NSMutableArray alloc]init];
    self.xAxisLabelsArray =    [[NSMutableArray alloc]init];
    self.chartLineWidth =      1.0f;
    
}

//##########################################
//###            UiViewUtils             ###
//##########################################
#pragma mark UiViewUtils

- (UILabel *)makeLabelWith:(CGRect) rect title:(NSString *) title
{
    UILabel *uiL = [[UILabel alloc]initWithFrame:rect];
    
    [uiL setFont:[uiL.font fontWithSize:AXIS_FONT_SIZE]];
    [uiL setTextColor:self.fontColor];
    [uiL setTextAlignment:NSTextAlignmentCenter];
    [uiL setNumberOfLines:2];
    [uiL setText:title];
    
    return uiL;
}

//##########################################
//###            Animation               ###
//##########################################
#pragma mark Animation

-(void)back
{
    [self animateGraphChangesWithDirection:BACK];
}

-(void)fwd
{
    [self animateGraphChangesWithDirection:FWD];
}

-(void)animateGraphChangesWithDirection:(AnimationDirection) direction
{
    
    if (self.swiping)
        return;
    
    [self setSwiping:true];
    
    [UIView animateWithDuration:1.0f animations:^{
        
        [self.graphShapedLine setStrokeColor:[[UIColor clearColor] CGColor]];
        
    }];
    
    // MOve balls out of screen
    
    for(int i = 0; i < [self.uiViewPointsArray count]; i++)
    {
        
        UIView *dot = [self.uiViewPointsArray objectAtIndex:i];
        
        [UIView animateWithDuration:0.5f animations:^{
            
            switch (direction) {
                case FWD:
                    dot.frame = CGRectMake(dot.frame.origin.x + (self.superview.frame.size.width * 1.1f), dot.frame.origin.y, dot.frame.size.width, dot.frame.size.height);
                    break;
                    
                case BACK:
                    dot.frame = CGRectMake(dot.frame.origin.x - (self.superview.frame.size.width * 1.1f), dot.frame.origin.y, dot.frame.size.width, dot.frame.size.height);
                    break;
                    
                default:
                    break;
            }
            
        } completion:^(BOOL finished){
            
            if(!self.redrawing){
                [self setRedrawing:true];
                [self reloadDataAnimated:NO direction:direction];
            }
            
        }];
        
    }
    
    // Move labels out of screen
    
    for(int i = 0; i < [self.xAxisLabelsArray count]; i++)
    {
        UILabel *lbl = [self.xAxisLabelsArray objectAtIndex:i];
        
        [UIView animateWithDuration:0.5f animations:^{
            
            switch (direction) {
                case FWD:
                    lbl.frame = CGRectMake(lbl.frame.origin.x + (self.superview.frame.size.width * 1.1f), lbl.frame.origin.y, lbl.frame.size.width, lbl.frame.size.height);
                    break;
                    
                case BACK:
                    lbl.frame = CGRectMake(lbl.frame.origin.x - (self.superview.frame.size.width * 1.1f), lbl.frame.origin.y, lbl.frame.size.width, lbl.frame.size.height);
                    break;
                    
                default:
                    break;
            }
            
        }];
    }
    
}

//##########################################
//###        ChartViewReloadData         ###
//##########################################
#pragma mark ChartViewReloadData

- (void)reloadDataAnimated:(BOOL)animated direction:(AnimationDirection)direction
{
    [self clear];
    [self drawChartAxis];
    
    NSInteger numberofVerticalLines = [self.dataSource numberOfVerticalLinesInChartView:self];
    NSInteger numberofHorizontalLines = [self.dataSource numberOfHorizontalLinesInChartView:self];
    
    //#################################################
    //### Draw Y scale values with horizontal lines ###
    //#################################################
    [self drawYscale:numberofHorizontalLines];
    
    // Draw X scale values with vertical lines
    float xLabelDistance = (self.frame.size.width - VERT_OFFSET) / numberofVerticalLines;
    
    for(int i = 0; i < numberofVerticalLines; i++)
    {
        CGRect verticalLineFrame = [self drawVerticalLinesAt:i withDistance:xLabelDistance];
        
        [self drawHorizontalValueLabelAt:i forLineRect:verticalLineFrame withDistance:xLabelDistance andDirection:direction];
        [self drawPointAt:i withDistance:xLabelDistance andDirection:direction];
        
    }

    
}

//##########################################
//###         ReloadData Methods         ###
//##########################################
#pragma mark ReloadData Methods

    //##########################################
    //###               Y scale              ###
    //##########################################
- (void) drawYscale:(NSInteger)numberofHorizontalLines
{
    // Draw Y scale values with horizontal lines
    
    float yLabelDistance = self.frame.size.height / numberofHorizontalLines;
    float verticalLabelPositionOffset = self.frame.origin.x;
    
    CGRect horizontalLineFrame;
    CGRect verticalValueFrame;
    
    float x;
    float y;
    float width;
    float height;
    
    for(int i = 1; i <= numberofHorizontalLines; i++)
    {
        
        // ### Compute frame values for horizontal line at index ###
        x = AXIS_WIDTH;
        y = yLabelDistance * i+1;
        width = self.frame.size.width - AXIS_WIDTH;
        height = AXIS_WIDTH;
        
        horizontalLineFrame = CGRectMake(x, y, width, height);
        
        // ### Compute frame values for vertical value-label at index ###
        x = -verticalLabelPositionOffset;
        y = (yLabelDistance * i+1)-(yLabelDistance / TWO)-(AXIS_FONT_SIZE / TWO);
        width = verticalLabelPositionOffset;
        height = yLabelDistance;
        
        verticalValueFrame = CGRectMake(x, y, width, height);
        
        
        NSString *title = [self.dataSource smartChartView:self titleForVerticalYLabelAtIndex:i-1];
        
        [self addSubview:[self makeLabelWith:verticalValueFrame title:title]];
        
        UIView *horizontalLine = [[UIView alloc]initWithFrame:horizontalLineFrame];
        
        if(i != numberofHorizontalLines)
            horizontalLine.backgroundColor = self.horizontalLineColor;
        
        [self addSubview:horizontalLine];
        
        
    }
    
    
}

    //##########################################
    //###           Vertical Lines           ###
    //##########################################
- (CGRect) drawVerticalLinesAt:(int) index withDistance:(float) distance
{
    float x = (distance * index) + VERT_OFFSET;
    float height = self.frame.size.height - AXIS_WIDTH;
    
    UIView *verticalLine = [[UIView alloc]
                            initWithFrame:CGRectMake(x, 0, AXIS_WIDTH, height)];
    
    verticalLine.backgroundColor = self.verticalLineColor;
    
    [self.verticalLinesArray addObject:verticalLine];
    [self addSubview:verticalLine];
    
    return [verticalLine frame];
}

    //##########################################
    //###       Horizontal Value Views       ###
    //##########################################
- (void) drawHorizontalValueLabelAt:(int)index forLineRect:(CGRect) verticalLineFrame withDistance:(float)distance andDirection:(AnimationDirection)direction
{
    CGRect horizontalValueFrame = verticalLineFrame;
    horizontalValueFrame.origin.y = self.frame.size.height + self.labelValeOffset;
    horizontalValueFrame.origin.x = (distance * index - (distance / TWO)) + VERT_OFFSET;
    horizontalValueFrame.size.width = distance;
    horizontalValueFrame.size.height = distance * 1.1f;
    
    if([self.delegate respondsToSelector:@selector(smartChartView:viewToDisplayForHorizontalValueAtIndex:)]
       && [self.delegate smartChartView:self viewToDisplayForHorizontalValueAtIndex:index] != nil)
    {
        UILabel *label = [self.delegate smartChartView:self viewToDisplayForHorizontalValueAtIndex:index];
        CGRect tmpRect = label.frame;
        //            tmpRect.size.width = horizontalValueFrame.size.width;
        tmpRect.origin = horizontalValueFrame.origin;
        tmpRect.origin.x = (verticalLineFrame.origin.x - (tmpRect.size.width / TWO));
        label.frame = tmpRect;
        
        [self.xAxisLabelsArray addObject:label];
        [self addSubview:label];
        
        switch (direction) {
                
            case BACK:
            {
                label.frame = CGRectMake(label.frame.origin.x + (self.superview.frame.size.width * 1.1f) , label.frame.origin.y, label.frame.size.width, label.frame.size.height);
                
                [UIView animateWithDuration:0.5f animations:^{
                    label.frame = CGRectMake(label.frame.origin.x - (self.superview.frame.size.width * 1.1f) , label.frame.origin.y, label.frame.size.width, label.frame.size.height);
                }];
            }
                break;
                
            case FWD:
            {
                label.frame = CGRectMake(label.frame.origin.x - (self.superview.frame.size.width * 1.1f) , label.frame.origin.y, label.frame.size.width, label.frame.size.height);
                
                [UIView animateWithDuration:0.5f animations:^{
                    label.frame = CGRectMake(label.frame.origin.x + (self.superview.frame.size.width * 1.1f) , label.frame.origin.y, label.frame.size.width, label.frame.size.height);
                }];
            }
                break;
                
            case NONE: /* DO NOTHING */ break;
                
        }
        
    }
    

}

- (void) drawPointAt:(int)index withDistance:(float)xLabelDistance andDirection:(AnimationDirection)direction
{
    // Compute the position and add the point
    UIView *point;
    
    if([self.delegate respondsToSelector:@selector(smartChartView:viewForDotAtHorizontalIndex:)])
    {
        point = [self.delegate smartChartView:self viewForDotAtHorizontalIndex:index];
        CGRect newFrame = point.frame;
        newFrame.origin.x = (xLabelDistance * index - ((newFrame.size.width/TWO) - AXIS_WIDTH)) + VERT_OFFSET;
        newFrame.origin.y = /*self.frame.size.height/TWO*/ 0;
        point.frame = newFrame;
    }
    else
    {
        CGRect pointFrame = CGRectMake(xLabelDistance * index - (4.5f),
                                       /*self.frame.size.height/TWO*/ 0, 10, 10);
        
        point = [[UIView alloc]initWithFrame:pointFrame];
        point.backgroundColor = [UIColor greenColor];
        
    }

    NSInteger value = [self.dataSource smartChartView:self xAxisValueForDotAtHorizontalIndex:index];
    
    switch (direction)
    {
        case BACK:
            
        {
            [self.uiViewPointsArray addObject:point];
            
            point.frame = CGRectMake(point.frame.origin.x + (self.superview.frame.size.width * 1.1f) , point.frame.origin.y, point.frame.size.width, point.frame.size.height);
            
            [self addSubview:point];
            
            [UIView animateWithDuration:0.5f animations:^{
                
                point.frame = CGRectMake(point.frame.origin.x - (self.superview.frame.size.width * 1.1f) , point.frame.origin.y, point.frame.size.width, point.frame.size.height);
                
            } completion:^(BOOL finished){
                
                
                [self setHeight:point value:value index:index];
                
            }];
            
        }
            break;
        case FWD:
            
        {
            [self.uiViewPointsArray addObject:point];
            
            point.frame = CGRectMake(point.frame.origin.x - (self.superview.frame.size.width * 1.1f) , point.frame.origin.y, point.frame.size.width, point.frame.size.height);
            
            [self addSubview:point];
            
            [UIView animateWithDuration:0.5f animations:^{
                
                point.frame = CGRectMake(point.frame.origin.x + (self.superview.frame.size.width * 1.1f) , point.frame.origin.y, point.frame.size.width, point.frame.size.height);
                
            } completion:^(BOOL finished){
                
                [self setHeight:point value:value index:index];
                
            }];
            
        }
            break;
            
        case NONE:
        {
            [self.uiViewPointsArray addObject:point];
            [self addSubview:point];
            [self setHeight:point value:value index:index];
        }
            break;
            
        default:
            
            break;
    }

    
    
}

/////
-(void)setHeight:(UIView *)view value:(NSInteger)value index:(int) i
{
    
    value -= self.minValue;
    
    float xLabelDistance = self.frame.size.height / [self.dataSource numberOfHorizontalLinesInChartView:self];
    float pixilLimit = self.frame.size.height - xLabelDistance;
    float percentage = (value / (self.maxValue - self.minValue)) * HUNDRED;
    float pixlPercentage = (percentage / HUNDRED) * pixilLimit;
    
    CGRect frameForYValue = view.frame;
    frameForYValue.origin.y = self.frame.size.height - pixlPercentage - ((view.frame.size.height / TWO) - AXIS_WIDTH);
    
    [UIView animateWithDuration:1.0f animations:^{
        view.frame = frameForYValue;
        
    }
                     completion:^(BOOL finished){
                         if(self.isConnectingDots)
                             return;
                         
                         [self setIsConnectingDots:true];
                         [self setSwiping:false];
                         [self setRedrawing:false];
                         
                         NSLog(@"connecting dots");
                         if(i == [self.uiViewPointsArray count] - 1)
                             [self connectDots];
                     }
     ];
    
}

-(void)connectDots
{
    if ([self.uiViewPointsArray count] == 0)
        return;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    BOOL lineStarted = NO;
    for (int i = 0; i < [self.uiViewPointsArray count]; i++) {
        if([[self.uiViewPointsArray objectAtIndex:i] tag] == EMPTY_DOT)
            continue;
        
        if(!lineStarted){
            lineStarted = YES;
            [path moveToPoint:[self normalizedPoint:[self.uiViewPointsArray objectAtIndex:i]]];
        }
        
        [path addLineToPoint:[self normalizedPoint:[self.uiViewPointsArray objectAtIndex:i]]];
        
    }
    
    UIView *f = [self.uiViewPointsArray objectAtIndex:0];
    
    self.graphShapedLine = [CAShapeLayer layer];
    self.graphShapedLine.path = [path CGPath];
    self.graphShapedLine.strokeColor = [self.graphLineColor CGColor];
    self.graphShapedLine.lineWidth = self.chartLineWidth;
    self.graphShapedLine.fillColor = [[UIColor clearColor] CGColor];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    pathAnimation.duration = 0.5f;
    pathAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    pathAnimation.toValue = [NSNumber numberWithFloat:1.0f];
    [self.graphShapedLine addAnimation:pathAnimation forKey:@"strokeEndAnimation"];
    
    [self.layer insertSublayer:self.graphShapedLine below:f.layer];
    
}
-(CGPoint) normalizedPoint:(UIView *)view
{
    float offset = view.frame.size.height / TWO;
    return CGPointMake(view.frame.origin.x + offset, view.frame.origin.y + offset);
}
/////

//##########################################
//###       Drawing/Redraw Axis          ###
//##########################################
#pragma mark Drawing Axis

-(void)clear
{
    [self setIsConnectingDots:false];
    
    [self.uiViewPointsArray removeAllObjects];
    [self.verticalLinesArray removeAllObjects];
    [self.xAxisLabelsArray removeAllObjects];
    
    for (UIView *view in [self subviews])
        [view removeFromSuperview];

    [self.layer setSublayers:nil];
}

-(void)drawChartAxis
{
    
    // Drawing X axis
    CGRect yAxisFrame = CGRectMake(0, 0, AXIS_WIDTH, self.frame.size.height);
    UIView *yAxis = [[UIView alloc]initWithFrame:yAxisFrame];
    [yAxis setBackgroundColor:self.axisColor];
    
    [self drawArrow: CGPointMake(AXIS_WIDTH / TWO, 0) direction:ARROW_UP];
    
    // Drawing Y axis
    CGRect xAxisFrame = CGRectMake(0, self.frame.size.height - AXIS_WIDTH, self.frame.size.width, AXIS_WIDTH);
    UIView *xAxis = [[UIView alloc]initWithFrame:xAxisFrame];
    [xAxis setBackgroundColor:self.axisColor];
    
    [self drawArrow: CGPointMake(xAxisFrame.size.width, xAxisFrame.origin.y + (AXIS_WIDTH / TWO)) direction:ARROW_RIGHT];
    
    [self addSubview:yAxis];
    [self addSubview:xAxis];
    
}

- (void)drawArrow:(CGPoint)point direction:(int)direction
{
    CGPoint leftEnd;
    CGPoint rightEnd;
    
    switch (direction)
    {
        case ARROW_UP:
            leftEnd = CGPointMake(point.x - 2, point.y + 5);
            rightEnd = CGPointMake(point.x + 2, point.y + 5);
            break;
        case ARROW_RIGHT:
            leftEnd = CGPointMake(point.x - 5, point.y + 2);
            rightEnd = CGPointMake(point.x - 5, point.y - 2);
            break;
            
        default:
            NSLog(@"DRAW_ARROW_ERROR: Unsupported arrow direction");
            return;
    }
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:point];
    [path addLineToPoint:rightEnd];
    [path moveToPoint:point];
    [path addLineToPoint:leftEnd];
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    [shapeLayer setPath:[path CGPath]];
    [shapeLayer setStrokeColor:[self.axisColor CGColor]];
    [shapeLayer setLineWidth:AXIS_WIDTH];
    [shapeLayer setFillColor:[[UIColor clearColor] CGColor]];
    
    [self.layer addSublayer:shapeLayer];
    
}

@end
