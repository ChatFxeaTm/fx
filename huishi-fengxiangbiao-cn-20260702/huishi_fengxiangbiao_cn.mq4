//+------------------------------------------------------------------+
//| 汇市风向标_中文汉化版.mq4                                      |
//| 类型：MT4 主图趋势通道突破指标                                  |
//| 说明网址：https://chatfxeatm.github.io/fx/huishi-fengxiangbiao-cn-20260702/ |
//|                                                                  |
//| 汉化与清理说明：                                                 |
//| 1. 保留原始趋势通道、信号、统计、报警、按钮显示逻辑。            |
//| 2. 汉化参数、注释、指标名称、报警文字和统计面板文字。            |
//| 3. 清理原文件末尾与指标计算无关的混淆面板代码，提升可读性。      |
//| 4. 本指标只提供趋势提示与历史统计，不保证盈利，不构成投资建议。  |
//+------------------------------------------------------------------+
#property link        "https://chatfxeatm.github.io/fx/huishi-fengxiangbiao-cn-20260702/"
#property description "汇市风向标：趋势通道突破指标，显示趋势区间、突破信号、模拟出场与统计信息。"
#property description "风险提示：指标不能保证盈利，市场、网络、滑点、点差等风险均需自行承担。"
#property description "汉化更新时间：2026.07.02"

#property indicator_chart_window
#property indicator_buffers 6
#property indicator_color1 clrLimeGreen
#property indicator_color2 clrCoral
#property indicator_color3 clrGreen
#property indicator_color4 clrFireBrick
#property indicator_color5 clrLimeGreen
#property indicator_color6 clrCoral

//+------------------------------------------------------------------+
//| 价格源枚举                                                       |
//+------------------------------------------------------------------+
enum ENUM_PRICE
{
   close,              // 收盘价
   median,             // 中间价：(High + Low) / 2
   typical,            // 典型价：(High + Low + Close) / 3
   weightedClose,      // 加权收盘价：(High + Low + 2 * Close) / 4
   heikenAshiClose,    // 平均K线收盘价
   heikenAshiMedian,   // 平均K线中间价
   heikenAshiTypical,  // 平均K线典型价
   heikenAshiWeighted  // 平均K线加权收盘价
};

//+------------------------------------------------------------------+
//| 指标参数                                                         |
//+------------------------------------------------------------------+
input string     UniqueName              = "汇市风向标";       // 指标对象名前缀，多个指标同图时必须不同
input ENUM_PRICE Price                   = heikenAshiClose;    // 趋势突破判断使用的价格源
input int        ChannelPeriod           = 5;                  // 基础通道周期：用于寻找最近高低点
input int        MaxChannelPeriod        = 30;                 // 最大通道周期：通道太窄时向外扩展到该周期
input double     Margin                  = 0.0;                // 通道内缩比例，0=不内缩
input double     MinChannelWidth         = 10.0;               // 最小通道宽度，单位为指标内部点值
input color      UpTrendColor            = Yellow;             // 上升趋势区间颜色
input color      DnTrendColor            = White;              // 下跌趋势区间颜色
input bool       ShowFilledBoxes         = true;               // 是否显示趋势区间矩形
input bool       ShowChannel             = true;               // 是否显示上下通道线

input string     ArrowStuffs             = "=== 箭头设置 ==="; // 分组：箭头设置
input int        UpArrowCode             = 233;                // 上升信号箭头代码
input int        UpArrowSize             = 2;                  // 上升信号箭头大小
input color      UpArrowColor            = clrRed;             // 上升信号箭头颜色
input int        DownArrowCode           = 234;                // 下降信号箭头代码
input int        DownArrowSize           = 2;                  // 下降信号箭头大小
input color      DownArrowColor          = clrLimeGreen;       // 下降信号箭头颜色

input string     AnalysisSets            = "=== 交易统计设置 ==="; // 分组：交易统计
input bool       ShowAnalysis            = true;               // 是否启用历史信号模拟统计
input bool       ShowStatsComment        = false;              // 是否在左上角显示统计面板
input bool       ShowArrows              = false;              // 是否额外绘制开平仓箭头对象
input bool       ShowProfit              = true;               // 是否显示每段模拟收益点数
input bool       ShowExits               = true;               // 是否显示模拟出场点
input color      WinColor                = clrLimeGreen;       // 盈利标记颜色
input color      LossColor               = clrTomato;          // 亏损标记颜色

input string     Alerts                  = "=== 报警与推送设置 ==="; // 分组：报警设置
input bool       AlertOn                 = true;               // 是否弹窗报警
input int        AlertShift              = 1;                  // 报警K线：0=当前K线，1=上一根已完成K线
input int        SoundsNumber            = 5;                  // 信号出现后声音提醒次数
input int        SoundsPause             = 5;                  // 两次声音提醒间隔，单位秒
input string     UpTrendSound            = "news.wav";         // 上升信号声音文件
input string     DnTrendSound            = "news.wav";         // 下降信号声音文件
input bool       EmailOn                 = true;               // 是否发送邮件提醒
input int        EmailsNumber            = 1;                  // 每次信号发送邮件数量
input bool       PushNotificationOn      = true;               // 是否发送手机推送

input string     ButtonSettings          = "=== 按钮设置 ===";   // 分组：按钮设置
input int        btn_Subwindow           = 0;                  // 按钮所在窗口，0=主图窗口
input ENUM_BASE_CORNER btn_corner        = CORNER_LEFT_UPPER;  // 按钮锚点位置
input string     btn_text                = "风向标";            // 按钮显示文字
input string     btn_Font                = "Arial";            // 按钮字体
input int        btn_FontSize            = 9;                  // 按钮字号
input color      btn_text_ON_color       = clrLime;            // 指标开启时按钮文字颜色
input color      btn_text_OFF_color      = clrRed;             // 指标关闭时按钮文字颜色
input color      btn_background_color    = clrDimGray;         // 按钮背景色
input color      btn_border_color        = clrBlack;           // 按钮边框色
input int        button_x                = 20;                 // 按钮X坐标
input int        button_y                = 85;                 // 按钮Y坐标
input int        btn_Width               = 80;                 // 按钮宽度
input int        btn_Height              = 20;                 // 按钮高度
input string     UniqueButtonID          = "Charted trend";    // 按钮唯一ID，多个指标同图时必须不同

input string     LicenseSettings         = "=== 授权设置 ===";   // 分组：授权设置
input bool       EnableExpiryCheck       = true;               // 是否启用到期时间限制
input datetime   LicenseExpiryTime       = D'2026.09.30 12:00';// 指标到期时间
input string     ContactInfo             = "QQ:2026904767";    // 授权/售后联系方式

//+------------------------------------------------------------------+
//| 全局变量与指标缓冲区                                             |
//+------------------------------------------------------------------+
bool     show_data;
bool     recalc = false;
string   IndicatorObjPrefix;
string   buttonId;

double   UpSignal[], DnSignal[], UpBand[], LoBand[], buyexit[], sellexit[];
double   trend[], buycnt[], sellcnt[], pf[];

int      timeframe;
int      buylosscnt[2], selllosscnt[2];
bool     buystop[2], sellstop[2];

double   _point;
double   buyopen[], buyclose[], sellopen[], sellclose[];
double   lobound, upbound;
double   totbuyprofit[2], totsellprofit[2], totbuyloss[2], totsellloss[2];

datetime buyopentime[], buyclosetime[], sellopentime[], sellclosetime[];
datetime prevtime;

string   short_name, TF, IndicatorName;

//+------------------------------------------------------------------+
//| 指标初始化                                                       |
//+------------------------------------------------------------------+
int OnInit()
{
   if(EnableExpiryCheck && TimeCurrent() > LicenseExpiryTime)
   {
      Alert("指标授权已过期，请联系作者：" + ContactInfo);
      return(INIT_FAILED);
   }

   IndicatorDigits(Digits);
   IndicatorObjPrefix = "__" + btn_text + "__";

   // 按钮ID必须唯一，避免同图多个指标实例互相覆盖。
   buttonId = "_" + UniqueButtonID + IndicatorObjPrefix + "_BT_";

   if(ObjectFind(0, buttonId) < 0)
   createButton(buttonId, btn_text, btn_Width, btn_Height, btn_Font, btn_FontSize,
   btn_background_color, btn_border_color, btn_text_ON_color);

   ObjectSetInteger(0, buttonId, OBJPROP_YDISTANCE, button_y);
   ObjectSetInteger(0, buttonId, OBJPROP_XDISTANCE, button_x);

   OnInit2();

   show_data = (bool)ObjectGetInteger(0, buttonId, OBJPROP_STATE);

   if(show_data)
   ObjectSetInteger(0, buttonId, OBJPROP_COLOR, btn_text_ON_color);
   else
   ObjectSetInteger(0, buttonId, OBJPROP_COLOR, btn_text_OFF_color);

   return(INIT_SUCCEEDED);
}

void createButton(string buttonID, string buttonText, int width2, int height, string font, int fontSize, color bgColor, color borderColor, color txtColor)
{
   ObjectDelete (0,buttonID);
   ObjectCreate (0,buttonID,OBJ_BUTTON,btn_Subwindow,0,0);
   ObjectSetInteger(0,buttonID,OBJPROP_COLOR,txtColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BGCOLOR,bgColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BORDER_COLOR,borderColor);
   ObjectSetInteger(0,buttonID,OBJPROP_BORDER_TYPE,BORDER_RAISED);
   ObjectSetInteger(0,buttonID,OBJPROP_XSIZE,width2);
   ObjectSetInteger(0,buttonID,OBJPROP_YSIZE,height);
   ObjectSetString (0,buttonID,OBJPROP_FONT,font);
   ObjectSetString (0,buttonID,OBJPROP_TEXT,buttonText);
   ObjectSetInteger(0,buttonID,OBJPROP_FONTSIZE,fontSize);
   ObjectSetInteger(0,buttonID,OBJPROP_SELECTABLE,0);
   ObjectSetInteger(0,buttonID,OBJPROP_CORNER,btn_corner);
   ObjectSetInteger(0,buttonID,OBJPROP_HIDDEN,1);
   ObjectSetInteger(0,buttonID,OBJPROP_XDISTANCE,9999);
   ObjectSetInteger(0,buttonID,OBJPROP_YDISTANCE,9999);
   // 创建按钮后默认设置为开启状态，指标加载后默认显示
   ObjectSetInteger(0, buttonID, OBJPROP_STATE, true);
}
//+------------------------------------------------------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   // 如果只是切换周期，不删除按钮，这样可以保留按钮开关状态。
   if(reason != REASON_CHARTCHANGE) ObjectDelete(buttonId);
   deinit2();
}
//+------------------------------------------------------------------------------------------------------------------+
void OnChartEvent(const int id, // 图表事件处理：不要随意修改参数签名
const long &lparam,
const double &dparam,
const string &sparam)
{
   // 如果同图其他指标启用了对象创建/删除/鼠标事件，这里直接跳过无关事件，避免冲突。
   // 这些事件本指标不需要，跳过可以降低 MT4 卡死风险。
   if(id == CHARTEVENT_OBJECT_CREATE || id == CHARTEVENT_OBJECT_DELETE) return; // 跳过对象创建/删除事件，提升兼容性。
   if(id == CHARTEVENT_MOUSE_MOVE || id == CHARTEVENT_MOUSE_WHEEL) return; // 跳过鼠标移动/滚轮事件。
   if (id==CHARTEVENT_OBJECT_CLICK && sparam == buttonId)
   {
      show_data = ObjectGetInteger(0, buttonId, OBJPROP_STATE);

      if (show_data)
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_ON_color);
         OnInit2();
         // 从关闭切回开启后，重新计算一次全部历史数据。
         recalc=true;
         mystart();
      }
      else
      {
         ObjectSetInteger(0,buttonId,OBJPROP_COLOR,btn_text_OFF_color);
         for(int hiddenBuffer = 0; hiddenBuffer < 6; hiddenBuffer++)
         SetIndexStyle(hiddenBuffer, DRAW_NONE);
         deinit2();
      }
   }
}
//Forex-Station button template end42; copy and paste
//+------------------------------------------------------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| 指标参数与缓冲区初始化                                           |
//+------------------------------------------------------------------+
int OnInit2()
{
   timeframe = Period();
   TF = tf(timeframe);

   int drawmode = (ShowChannel ? DRAW_LINE : DRAW_NONE);
   IndicatorDigits(Digits);
   //---- drawing settings
   IndicatorBuffers(10);
   SetIndexBuffer(0,UpSignal); SetIndexStyle(0,DRAW_ARROW,EMPTY,UpArrowSize,UpArrowColor); SetIndexArrow(0,UpArrowCode);
   SetIndexBuffer(1,DnSignal); SetIndexStyle(1,DRAW_ARROW,EMPTY,DownArrowSize,DownArrowColor); SetIndexArrow(1,DownArrowCode);
   SetIndexBuffer(2, UpBand); SetIndexStyle(2,drawmode );
   SetIndexBuffer(3, LoBand); SetIndexStyle(3,drawmode );
   SetIndexBuffer(4, buyexit); SetIndexStyle(4,DRAW_ARROW);
   SetIndexBuffer(5,sellexit); SetIndexStyle(5,DRAW_ARROW);
   SetIndexBuffer(6, trend);
   SetIndexBuffer(7, buycnt);
   SetIndexBuffer(8, sellcnt);
   SetIndexBuffer(9, pf);

   int draw_begin = ChannelPeriod;
   //----
   IndicatorName = WindowExpertName();
   short_name = IndicatorName+"["+TF+"]("+ChannelPeriod+")";
   IndicatorShortName(short_name);
   SetIndexLabel(0,"上升趋势信号");
   SetIndexLabel(1,"下降趋势信号");
   SetIndexLabel(2,"上轨通道");
   SetIndexLabel(3,"下轨通道");


   SetIndexDrawBegin(0,draw_begin);
   SetIndexDrawBegin(1,draw_begin);
   SetIndexDrawBegin(2,draw_begin);
   SetIndexDrawBegin(3,draw_begin);


   SetIndexEmptyValue(4,0);
   SetIndexEmptyValue(5,0);
   SetIndexEmptyValue(7,0);
   SetIndexEmptyValue(8,0);

   _point = Point*MathPow(10,Digits%2);
   //---- initialization done
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| 指标辅助清理函数                                                 |
//+------------------------------------------------------------------+
int deinit2()
{
   Comment("");
   ObjectsDeleteAll(0,UniqueName);

   ChartRedraw();
   return(0);
}
//+------------------------------------------------------------------+
//| 趋势通道突破系统核心                                             |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------------------------------------------------------+
int start()
{
   return(mystart());
}
//+------------------------------------------------------------------------------------------------------------------+
int mystart()
{
   if (show_data)
   {
      int shift, limit, counted_bars = IndicatorCounted();
      double buyprofit, sellprofit;
      color buycolor, sellcolor;
      string pftext;
      if(recalc)
      {
         // 按钮从关闭切换为开启后，需要重新计算全部历史数据。
         counted_bars = 0;
         recalc=false;
      }
      //----
      if(counted_bars > 0) limit = Bars - counted_bars - 1;
      if(counted_bars < 0) return(0);
      if(counted_bars < 1)
      {
         limit = Bars - 1;
         for(int i=limit;i>=0;i--)
         {
            UpBand[i] = EMPTY_VALUE;
            LoBand[i] = EMPTY_VALUE;
            UpSignal[i] = EMPTY_VALUE;
            DnSignal[i] = EMPTY_VALUE;
            buyexit[i] = 0;
            sellexit[i] = 0;
         }
      }



      for(shift=limit; shift>=0; shift--)
      {
         if(Time[shift] != prevtime)
         {
            buystop[1] = buystop[0];
            sellstop[1] = sellstop[0];
            prevtime = Time[shift];
         }


         int maxperiod = MaxChannelPeriod;
         int hhbar = iHighest(NULL,0,MODE_HIGH,ChannelPeriod,shift);
         int llbar = iLowest (NULL,0,MODE_LOW ,ChannelPeriod,shift);
         double hh = High[hhbar];
         double ll = Low [llbar];
         double width = (hh - ll)*(1 - 2*Margin);

         if(shift > Bars - maxperiod) continue;

         if(width < MinChannelWidth*_point)
         {
            for(i=ChannelPeriod+1;i<=maxperiod;i++)
            {
               hhbar = iHighest(NULL,0,MODE_HIGH,i,shift);
               llbar = iLowest (NULL,0,MODE_LOW ,i,shift);

               hh = High[hhbar];
               ll = Low [llbar];

               width = (hh - ll)*(1 - 2*Margin);

               if(width >= MinChannelWidth*_point) break;
               else
               {
                  if(i >= maxperiod && shift + i < Bars - 2) maxperiod = maxperiod + 1;
                  else
                  continue;
               }
            }
         }

         UpBand[shift] = hh - width*Margin;
         LoBand[shift] = ll + width*Margin;

         trend[shift] = trend[shift+1];

         if(priceWrapper(Price,shift) > UpBand[shift+1]) trend[shift] = 1;
         if(priceWrapper(Price,shift) < LoBand[shift+1]) trend[shift] =-1;



         if(trend[shift+1] != trend[shift+2])
         {
            if(trend[shift+1] > 0) {totsellprofit[1] = totsellprofit[0]; totsellloss[1] = totsellloss[0]; selllosscnt[1] = selllosscnt[0];}
            if(trend[shift+1] < 0) {totbuyprofit[1] = totbuyprofit[0]; totbuyloss[1] = totbuyloss[0]; buylosscnt[1] = buylosscnt[0];}
         }


         UpSignal[shift] = EMPTY_VALUE;
         DnSignal[shift] = EMPTY_VALUE;
         buycnt[shift] = buycnt[shift+1];
         sellcnt[shift] = sellcnt[shift+1];
         buyexit[shift] = 0;
         sellexit[shift] = 0;
         buystop[0] = buystop[1];
         sellstop[0] = sellstop[1];


         if(trend[shift] > 0)
         {
            if(trend[shift+1] <= 0)
            {
               lobound = MathMin(LoBand[llbar],LoBand[MathMax(llbar,shift+ChannelPeriod)]);

               if(UpBand[shift+1] > 0 && UpBand[shift+1] != EMPTY_VALUE && lobound > 0 && lobound != EMPTY_VALUE)
               {
                  SetBox(UniqueName+" UpBox "+TimeToString(Time[shift]),0,Time[shift],UpBand[shift+1],Time[MathMax(llbar,shift+ChannelPeriod)],lobound,ShowFilledBoxes,clrNONE,1,UpTrendColor,1);
                  UpSignal[shift] = lobound;

                  if(ShowAnalysis)
                  {
                     buycnt[shift] = buycnt[shift+1] + 1;

                     ArrayResize(buyopen, (int)buycnt[shift]);
                     ArrayResize(buyclose, (int)buycnt[shift]);
                     ArrayResize(buyopentime, (int)buycnt[shift]);
                     ArrayResize(buyclosetime, (int)buycnt[shift]);

                     buyopen[(int)buycnt[shift]-1] = Close[shift];
                     buyopentime[(int)buycnt[shift]-1] = Time[shift];
                     buyclose[(int)buycnt[shift]-1] = buyopen[(int)buycnt[shift]-1];
                     buystop[0] = false;

                     if(ShowArrows)
                     {
                        ObjectDelete(UniqueName+" BuyOpen "+DoubleToStr(buycnt[shift],0));
                        plotArrow(UniqueName+" BuyOpen "+DoubleToStr(buycnt[shift],0),buyopentime[(int)buycnt[shift]-1],buyopen[(int)buycnt[shift]-1],1,UpTrendColor);
                     }
                  }
               }

               if(High[shift] >= upbound && !sellstop[0] && sellclose[(int)sellcnt[shift]-1] == sellopen[(int)sellcnt[shift]-1])
               {
                  sellclose[(int)sellcnt[shift]-1] = upbound;
                  sellclosetime[(int)sellcnt[shift]-1] = Time[shift];
                  sellstop[0] = true;

                  if(sellopentime[(int)sellcnt[shift]-1] > 0 && sellclosetime[(int)sellcnt[shift]-1] > 0)
                  {
                     if(sellclose[(int)sellcnt[shift]-1] <= sellopen[(int)sellcnt[shift]-1]) sellcolor = WinColor; else sellcolor = LossColor;
                     plotTrend(UniqueName+" SellTrend "+DoubleToStr(sellcnt[shift],0),sellopentime[(int)sellcnt[shift]-1],sellopen[(int)sellcnt[shift]-1],sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],2,0,sellcolor);
                     if(ShowArrows && trend[shift+1] < 0) plotArrow(UniqueName+" SellClose "+DoubleToStr(sellcnt[shift],0),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],3,DnTrendColor);
                     if(ShowExits) sellexit[shift] = sellclose[(int)sellcnt[shift]-1];
                  }


                  if(ShowProfit)
                  {
                     sellprofit = (sellopen[(int)sellcnt[shift]-1] - sellclose[(int)sellcnt[shift]-1])/_point;
                     if(sellprofit >= 0) totsellprofit[0] = totsellprofit[1] + sellprofit;
                     else
                     {
                        totsellloss[0] = totsellloss[1] - sellprofit;
                        selllosscnt[0] = selllosscnt[1] + 1;
                     }

                     ObjectDelete(0,UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0));

                     if(sellprofit >= 0) plotText(UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0),0,"+"+DoubleToStr(sellprofit,1),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],ANCHOR_RIGHT_UPPER,WinColor,"Arial",8);
                     else plotText(UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0),0,DoubleToStr(sellprofit,1),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],ANCHOR_RIGHT_LOWER,LossColor,"Arial",8);
                  }
               }
            }

            ObjectDelete(0,UniqueName+" DnBox "+TimeToString(Time[shift]));

            if(ShowAnalysis)
            {
               if(trend[shift+1] > 0)
               {
                  if(High[shift] > buyclose[(int)buycnt[shift]-1] && !buystop[0])
                  {
                     buyclose[(int)buycnt[shift]-1] = High[shift];
                     buyclosetime[(int)buycnt[shift]-1] = Time[shift];
                  }

                  if(Low[shift] <= lobound && !buystop[0] && buyclose[(int)buycnt[shift]-1] == buyopen[(int)buycnt[shift]-1])
                  {
                     buyclose[(int)buycnt[shift]-1] = lobound;
                     buyclosetime[(int)buycnt[shift]-1] = Time[shift];
                     buystop[0] = true;
                  }
               }


               ObjectDelete(0,UniqueName+" BuyTrend "+DoubleToStr(buycnt[shift],0));
               if(ShowArrows) ObjectDelete(0,UniqueName+" BuyClose "+DoubleToStr(buycnt[shift],0));

               if(buyopentime[(int)buycnt[shift]-1] > 0 && buyclosetime[(int)buycnt[shift]-1] > 0)
               {
                  if(buyclose[(int)buycnt[shift]-1] >= buyopen[(int)buycnt[shift]-1]) buycolor = WinColor; else buycolor = LossColor;
                  plotTrend(UniqueName+" BuyTrend "+DoubleToStr(buycnt[shift],0),buyopentime[(int)buycnt[shift]-1],buyopen[(int)buycnt[shift]-1],buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],2,0,buycolor);
                  if(ShowArrows && trend[shift+1] > 0) plotArrow(UniqueName+" BuyClose "+DoubleToStr(buycnt[shift],0),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],3,UpTrendColor);
                  if(ShowExits) buyexit[shift] = buyclose[(int)buycnt[shift]-1];
               }



               if(ShowProfit)
               {
                  buyprofit = (buyclose[(int)buycnt[shift]-1] - buyopen[(int)buycnt[shift]-1])/_point;
                  if(buyprofit >= 0) totbuyprofit[0] = totbuyprofit[1] + buyprofit;
                  else
                  {
                     totbuyloss[0] = totbuyloss[1] - buyprofit;
                     buylosscnt[0] = buylosscnt[1] + 1;
                  }

                  ObjectDelete(0,UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0));

                  if(buyprofit >= 0) plotText(UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0),0,"+"+DoubleToStr(buyprofit,1),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],ANCHOR_RIGHT_LOWER,WinColor,"Arial",8);
                  else plotText(UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0),0,DoubleToStr(buyprofit,1),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],ANCHOR_RIGHT_UPPER,LossColor,"Arial",8);
               }

               if(ShowArrows)
               if(ObjectGetInteger(0,UniqueName+" SellOpen "+DoubleToStr(sellcnt[shift]+1,0),OBJPROP_TIME) == Time[shift]) ObjectDelete(0,UniqueName+" SellOpen "+DoubleToStr(sellcnt[shift]+1,0));
            }
         }

         if(trend[shift] < 0)
         {
            if(trend[shift+1] >= 0)
            {
               upbound = MathMax(UpBand[hhbar],UpBand[MathMax(hhbar,shift+ChannelPeriod)]); //High[iHighest(NULL,0,MODE_HIGH,MathMax(hhbar - shift,ChannelPeriod),shift+1)];

               if(LoBand[shift+1] > 0 && LoBand[shift+1] != EMPTY_VALUE && upbound > 0 && upbound != EMPTY_VALUE)
               {
                  SetBox(UniqueName+" DnBox "+TimeToString(Time[shift]),0,Time[shift],LoBand[shift+1],Time[MathMax(hhbar,shift+ChannelPeriod)],upbound,ShowFilledBoxes,clrNONE,1,DnTrendColor,1);
                  DnSignal[shift] = upbound;

                  if(ShowAnalysis)
                  {
                     sellcnt[shift] = sellcnt[shift+1] + 1;

                     ArrayResize(sellopen, (int)sellcnt[shift]);
                     ArrayResize(sellclose, (int)sellcnt[shift]);
                     ArrayResize(sellopentime, (int)sellcnt[shift]);
                     ArrayResize(sellclosetime, (int)sellcnt[shift]);

                     //sellopen[(int)sellcnt[shift]-1] = HeikenAshi(0,0,shift);
                     sellopen[(int)sellcnt[shift]-1] = Close[shift];
                     sellopentime[(int)sellcnt[shift]-1] = Time[shift];
                     sellclose[(int)sellcnt[shift]-1] = sellopen[(int)sellcnt[shift]-1];
                     sellstop[0] = false;

                     if(ShowArrows)
                     {
                        ObjectDelete(UniqueName+" SellOpen "+DoubleToStr(sellcnt[shift],0));
                        plotArrow(UniqueName+" SellOpen "+DoubleToStr(sellcnt[shift],0),sellopentime[(int)sellcnt[shift]-1],sellopen[(int)sellcnt[shift]-1],2,DnTrendColor);
                     }
                  }
               }

               if(Low[shift] <= lobound && !buystop[0] && buyclose[(int)buycnt[shift]-1] == buyopen[(int)buycnt[shift]-1])
               {
                  buyclose[(int)buycnt[shift]-1] = lobound;
                  buyclosetime[(int)buycnt[shift]-1] = Time[shift];
                  buystop[0] = true;

                  if(buyopentime[(int)buycnt[shift]-1] > 0 && buyclosetime[(int)buycnt[shift]-1] > 0)
                  {
                     if(buyclose[(int)buycnt[shift]-1] >= buyopen[(int)buycnt[shift]-1]) buycolor = WinColor; else buycolor = LossColor;
                     plotTrend(UniqueName+" BuyTrend "+DoubleToStr(buycnt[shift],0),buyopentime[(int)buycnt[shift]-1],buyopen[(int)buycnt[shift]-1],buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],2,0,buycolor);
                     if(ShowArrows && trend[shift+1] > 0) plotArrow(UniqueName+" BuyClose "+DoubleToStr(buycnt[shift],0),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],3,UpTrendColor);
                     if(ShowExits) buyexit[shift] = buyclose[(int)buycnt[shift]-1];
                  }

                  if(ShowProfit)
                  {
                     buyprofit = (buyclose[(int)buycnt[shift]-1] - buyopen[(int)buycnt[shift]-1])/_point;
                     if(buyprofit >= 0) totbuyprofit[0] = totbuyprofit[1] + buyprofit;
                     else
                     {
                        totbuyloss[0] = totbuyloss[1] - buyprofit;
                        buylosscnt[0] = buylosscnt[1] + 1;
                     }

                     ObjectDelete(0,UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0));

                     if(buyprofit >= 0) plotText(UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0),0,"+"+DoubleToStr(buyprofit,1),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],ANCHOR_RIGHT_LOWER,WinColor,"Arial",8);
                     else plotText(UniqueName+" BuyProfit "+DoubleToStr(buycnt[shift],0),0,DoubleToStr(buyprofit,1),buyclosetime[(int)buycnt[shift]-1],buyclose[(int)buycnt[shift]-1],ANCHOR_RIGHT_UPPER,LossColor,"Arial",8);
                  }
               }
            }

            ObjectDelete(0,UniqueName+" UpBox "+TimeToString(Time[shift]));

            if(ShowAnalysis)
            {
               if(trend[shift+1] < 0)
               {
                  if(Low[shift] < sellclose[(int)sellcnt[shift]-1] && !sellstop[0])
                  {
                     sellclose[(int)sellcnt[shift]-1] = Low[shift];
                     sellclosetime[(int)sellcnt[shift]-1] = Time[shift];
                  }

                  if(High[shift] >= upbound && !sellstop[0] && sellclose[(int)sellcnt[shift]-1] == sellopen[(int)sellcnt[shift]-1])
                  {
                     sellclose[(int)sellcnt[shift]-1] = upbound;
                     sellclosetime[(int)sellcnt[shift]-1] = Time[shift];
                     sellstop[0] = true;
                  }
               }

               ObjectDelete(0,UniqueName+" SellTrend "+DoubleToStr(sellcnt[shift],0));
               if(ShowArrows) ObjectDelete(0,UniqueName+" SellClose "+DoubleToStr(sellcnt[shift],0));

               if(sellopentime[(int)sellcnt[shift]-1] > 0 && sellclosetime[(int)sellcnt[shift]-1] > 0)
               {
                  if(sellclose[(int)sellcnt[shift]-1] <= sellopen[(int)sellcnt[shift]-1]) sellcolor = WinColor; else sellcolor = LossColor;
                  plotTrend(UniqueName+" SellTrend "+DoubleToStr(sellcnt[shift],0),sellopentime[(int)sellcnt[shift]-1],sellopen[(int)sellcnt[shift]-1],sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],2,0,sellcolor);
                  if(ShowArrows && trend[shift+1] < 0) plotArrow(UniqueName+" SellClose "+DoubleToStr(sellcnt[shift],0),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],3,DnTrendColor);
                  if(ShowExits) sellexit[shift] = sellclose[(int)sellcnt[shift]-1];
               }


               if(ShowProfit)
               {
                  sellprofit = (sellopen[(int)sellcnt[shift]-1] - sellclose[(int)sellcnt[shift]-1])/_point;
                  if(sellprofit >= 0) totsellprofit[0] = totsellprofit[1] + sellprofit;
                  else
                  {
                     totsellloss[0] = totsellloss[1] - sellprofit;
                     selllosscnt[0] = selllosscnt[1] + 1;
                  }

                  ObjectDelete(0,UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0));

                  if(sellprofit >= 0) plotText(UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0),0,"+"+DoubleToStr(sellprofit,1),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],ANCHOR_RIGHT_UPPER,WinColor,"Arial",8);
                  else plotText(UniqueName+" SellProfit "+DoubleToStr(sellcnt[shift],0),0,DoubleToStr(sellprofit,1),sellclosetime[(int)sellcnt[shift]-1],sellclose[(int)sellcnt[shift]-1],ANCHOR_RIGHT_LOWER,LossColor,"Arial",8);
               }

               if(ObjectGetInteger(0,UniqueName+" BuyOpen "+DoubleToStr(buycnt[shift]+1,0),OBJPROP_TIME) == Time[shift]) ObjectDelete(0,UniqueName+" BuyOpen "+DoubleToStr(buycnt[shift]+1,0));
            }
         }

         if((totbuyloss[0] + totsellloss[0]) > 0) pf[shift] = (totbuyprofit[0] + totsellprofit[0])/(totbuyloss[0] + totsellloss[0]); else pf[shift] = 0;
      }





      if(ShowStatsComment)
      {
         if(pf[0] > 0) pftext = DoubleToStr(pf[0],1); else pftext = "n/a";

         if(sellcnt[0]==0 || buycnt[0]==0){
            Comment("\n","汇市风向标趋势系统（突破价格源：" + price_type(Price) + "）\n============================\n历史信号过少，暂无法统计");
         }else
         Comment( "\n","汇市风向标趋势系统（突破价格源：" + price_type(Price) + "）","\n",
         "============================","\n",
         "多头信号（胜率）：",buycnt[0]," (",DoubleToStr(100*(buycnt[0] - buylosscnt[0])/buycnt[0],1),"%)","\n",
         "空头信号（胜率）：",sellcnt[0]," (",DoubleToStr(100*(sellcnt[0] - selllosscnt[0])/sellcnt[0],1),"%)","\n",
         "盈亏因子：",pftext,"\n");
      }


      if(AlertOn || EmailOn || PushNotificationOn)
      {
         bool uptrend = trend[AlertShift] > 0 && trend[AlertShift+1] <= 0;
         bool dntrend = trend[AlertShift] < 0 && trend[AlertShift+1] >= 0;

         if(uptrend || dntrend)
         {
            if(isNewBar(timeframe))
            {
               if(AlertOn)
               {
                  BoxAlert(uptrend,"：买入信号 @ " +DoubleToStr(Close[AlertShift],Digits));
                  BoxAlert(dntrend,"：卖出信号 @ "+DoubleToStr(Close[AlertShift],Digits));
               }

               if(EmailOn)
               {
                  EmailAlert(uptrend,"买入" ,"：买入信号 @ " +DoubleToStr(Close[AlertShift],Digits),EmailsNumber);
                  EmailAlert(dntrend,"卖出","：卖出信号 @ "+DoubleToStr(Close[AlertShift],Digits),EmailsNumber);
               }

               if(PushNotificationOn)
               {
                  PushAlert(uptrend,"：买入信号 @ " +DoubleToStr(Close[AlertShift],Digits));
                  PushAlert(dntrend,"：卖出信号 @ "+DoubleToStr(Close[AlertShift],Digits));
               }
            }
            else
            {
               if(AlertOn)
               {
                  WarningSound(uptrend,SoundsNumber,SoundsPause,UpTrendSound,Time[AlertShift]);
                  WarningSound(dntrend,SoundsNumber,SoundsPause,DnTrendSound,Time[AlertShift]);
               }
            }
         }
      }
   } //if (show_data)
   //----
   return(0);
}
//+------------------------------------------------------------------+
datetime prevnbtime;
bool isNewBar(int tf)
{
   bool res = false;

   if(tf >= 0)
   {
      if(iTime(NULL,tf,0) != prevnbtime)
      {
         res = true;
         prevnbtime = iTime(NULL,tf,0);
      }
   }
   else res = true;

   return(res);
}
string prevmess;

bool BoxAlert(bool cond,string text)
{
   string mess = IndicatorName + "("+Symbol()+","+TF + ")" + text;

   if (cond && mess != prevmess)
   {
      Alert (mess);
      prevmess = mess;
      return(true);
   }

   return(false);
}
datetime pausetime;
bool Pause(int sec)
{
   if(TimeCurrent() >= pausetime + sec) {pausetime = TimeCurrent(); return(true);}

   return(false);
}
datetime warningtime;
void WarningSound(bool cond,int num,int sec,string sound,datetime curtime)
{
   static int i;

   if(cond)
   {
      if(curtime != warningtime) i = 0;
      if(i < num && Pause(sec)) {PlaySound(sound); warningtime = curtime; i++;}
   }
}
string prevemail;
bool EmailAlert(bool cond,string text1,string text2,int num)
{
   string subj = "来自 " + IndicatorName + " 的新" + text1 + "信号";
   string mess = IndicatorName + "("+Symbol()+","+TF + ")" + text2;

   if (cond && mess != prevemail)
   {
      if(subj != "" && mess != "") for(int i=0;i<num;i++) SendMail(subj, mess);
      prevemail = mess;
      return(true);
   }

   return(false);
}
string prevpush;

bool PushAlert(bool cond,string text)
{
   string push = IndicatorName + "("+Symbol() + "," + TF + ")" + text;

   if(cond && push != prevpush)
   {
      SendNotification(push);

      prevpush = push;
      return(true);
   }

   return(false);
}
string tf(int itimeframe)
{
   string result = "";

   switch(itimeframe)
   {
      case PERIOD_M1:  result = "M1";  break;
      case PERIOD_M5:  result = "M5";  break;
      case PERIOD_M15: result = "M15"; break;
      case PERIOD_M30: result = "M30"; break;
      case PERIOD_H1:  result = "H1";  break;
      case PERIOD_H4:  result = "H4";  break;
      case PERIOD_D1:  result = "D1";  break;
      case PERIOD_W1:  result = "W1";  break;
      case PERIOD_MN1: result = "MN1"; break;
      default:         result = "N/A"; break;
   }

   if(result == "N/A")
   {
      if(itimeframe < PERIOD_H1)       result = "M"  + IntegerToString(itimeframe);
      else if(itimeframe < PERIOD_D1)  result = "H"  + IntegerToString(itimeframe / PERIOD_H1);
      else if(itimeframe < PERIOD_W1)  result = "D"  + IntegerToString(itimeframe / PERIOD_D1);
      else if(itimeframe < PERIOD_MN1) result = "W"  + IntegerToString(itimeframe / PERIOD_W1);
      else                             result = "MN" + IntegerToString(itimeframe / PERIOD_MN1);
   }

   return(result);
}

//+------------------------------------------------------------------+
//| 绘制趋势区间矩形                                                 |
//+------------------------------------------------------------------+
void SetBox(string name,int win,datetime time1,double price1,datetime time2,double price2,bool fill,color bg_color,int border_type,color border_clr,int border_width)
{
   ObjectDelete(0,name);

   if(ObjectCreate(0,name,OBJ_RECTANGLE,win,0,0,0,0))
   {
      ObjectSetInteger(0,name,OBJPROP_TIME1 , time1);
      ObjectSetDouble (0,name,OBJPROP_PRICE1 , price1);
      ObjectSetInteger(0,name,OBJPROP_TIME2 , time2);
      ObjectSetDouble (0,name,OBJPROP_PRICE2 , price2);
      ObjectSetInteger(0,name,OBJPROP_COLOR , border_clr);
      ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE, border_type);
      ObjectSetInteger(0,name,OBJPROP_WIDTH ,border_width);
      ObjectSetInteger(0,name,OBJPROP_STYLE , STYLE_SOLID);
      ObjectSetInteger(0,name,OBJPROP_BACK , fill);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE , 1);
      ObjectSetInteger(0,name,OBJPROP_SELECTED , 0);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN , false);
      ObjectSetInteger(0,name,OBJPROP_ZORDER , 0);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR , bg_color);
   }
}
void plotArrow(string name,datetime time,double price,int arrow,color clr)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(0,name,OBJ_ARROW,0,time,price);
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE ,arrow);
      ObjectSetInteger(0,name,OBJPROP_COLOR , clr);
   }
   else ObjectSetInteger(0,name,OBJPROP_COLOR, clr);
}
void plotTrend(string name,datetime time1,double price1,datetime time2,double price2,int style,int width,color clr)
{
   if(ObjectFind(0,name) < 0)
   {
      ObjectCreate(0,name,OBJ_TREND,0,time1,price1,time2,price2);
      ObjectSetInteger(0,name,OBJPROP_STYLE,style);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
      ObjectSetInteger(0,name,OBJPROP_RAY ,false);
      ObjectSetInteger(0,name,OBJPROP_COLOR, clr);
   }
}

void plotText(string name,int win,string text,datetime time,double price,int anchor,color clr,string font,int fontsize)
{
   ObjectDelete(0,name);

   if(ObjectCreate(0,name,OBJ_TEXT,win,0,0))
   {
      ObjectSetInteger(0,name,OBJPROP_TIME , time);
      ObjectSetDouble (0,name,OBJPROP_PRICE , price);
      ObjectSetInteger(0,name,OBJPROP_COLOR , clr);
      ObjectSetString (0,name,OBJPROP_FONT , font);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE ,fontsize);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR , anchor);
      ObjectSetString (0,name,OBJPROP_TEXT , text);
   }
}
double priceWrapper(int price, int bar){
   if(price>=4)
   return(HeikenAshi(0,Price-4,bar));
   if(price>0)
   price+=3;
   return(iMA(Symbol(),0,1,0,0,price,bar));
}
// 平均K线价格计算
double haClose[1][2], haOpen[1][2], haHigh[1][2], haLow[1][2];
datetime prevhatime[1];
double HeikenAshi(int index,int price,int bar)
{
   if(prevhatime[index] != Time[bar])
   {
      haClose[index][1] = haClose[index][0];
      haOpen [index][1] = haOpen [index][0];
      haHigh [index][1] = haHigh [index][0];
      haLow [index][1] = haLow [index][0];
      prevhatime[index] = Time[bar];
   }

   if(bar == Bars - 1)
   {
      haClose[index][0] = Close[bar];
      haOpen [index][0] = Open [bar];
      haHigh [index][0] = High [bar];
      haLow [index][0] = Low [bar];
   }
   else
   {
      haClose[index][0] = (Open[bar] + High[bar] + Low[bar] + Close[bar])/4;
      haOpen [index][0] = (haOpen[index][1] + haClose[index][1])/2;
      haHigh [index][0] = MathMax(High[bar],MathMax(haOpen[index][0],haClose[index][0]));
      haLow [index][0] = MathMin(Low [bar],MathMin(haOpen[index][0],haClose[index][0]));
   }

   switch(price)
   {
      case 0: return(haClose[index][0]); break;
      case 1: return((haHigh[index][0] + haLow[index][0])/2); break;
      case 2: return((haHigh[index][0] + haLow[index][0] + haClose[index][0])/3); break;
      case 3: return((haHigh[index][0] + haLow[index][0] + 2*haClose[index][0])/4); break;
      default: return(haClose[index][0]); break;
   }
}
string price_type(int price)
{
   switch(price)
   {
      case 0: return("收盘价");
      case 1: return("中间价");
      case 2: return("典型价");
      case 3: return("加权收盘价");
      case 4: return("平均K线收盘价");
      case 5: return("平均K线中间价");
      case 6: return("平均K线典型价");
      case 7: return("平均K线加权收盘价");
      default: return("未知价格源");
   }
}
