//
//  SmartChartView.h
//  SmartChartView
//
//  Created by Tereshkin Sergey on 02/03/15.
//  Copyright (c) 2015 App To You. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#define EMPTY_DOT 404
#define PEFT_OBJ_KEY @"pef_object"
#define VALUE_KEY @"value"

@class SmartChartView;

typedef enum animationType
{
    BACK,
    FWD,
    NONE
    
} AnimationDirection;

@protocol SmartChartViewDataSource

- (NSUInteger)numberOfHorizontalLinesInChartView:(SmartChartView *)smartChartView;
- (NSUInteger)numberOfVerticalLinesInChartView:(SmartChartView *)smartChartView;

- (NSUInteger)smartChartView:(SmartChartView *)smartChartView xAxisValueForDotAtHorizontalIndex:(NSUInteger)horizontalIndex;

- (NSString *)smartChartView:(SmartChartView *)smartChartView titleForVerticalYLabelAtIndex:(NSUInteger)verticalIndex;


@end

@protocol SmartChartViewDelegate <NSObject>

- (UIView *)smartChartView:(SmartChartView *)smartChartView viewForDotAtHorizontalIndex:(NSUInteger)horizontalIndex;
- (UILabel *)smartChartView:(SmartChartView *)smartChartView viewToDisplayForHorizontalValueAtIndex:(NSUInteger)horizontalIndex;

@end

@interface SmartChartView : UIView

// Chart data
@property (nonatomic) float minValue;
@property (nonatomic) float maxValue;

// Colors
@property (nonatomic, strong) UIColor *axisColor;
@property (nonatomic, strong) UIColor *fontColor;
@property (nonatomic, strong) UIColor *graphLineColor;
@property (nonatomic, strong) UIColor *verticalLineColor;
@property (nonatomic, strong) UIColor *horizontalLineColor;

// Dimentions
@property (nonatomic) float chartLineWidth;
@property (nonatomic) float labelValeOffset;

@property (nonatomic) BOOL swiping;

@property (nonatomic, weak) id<SmartChartViewDataSource> dataSource;
@property (nonatomic, weak) id <SmartChartViewDelegate> delegate;

- (id)initWithFrame:(CGRect)frame;
- (void)reloadDataAnimated:(BOOL)animated direction:(AnimationDirection)direction;

- (void)back;
- (void)fwd;


@end
