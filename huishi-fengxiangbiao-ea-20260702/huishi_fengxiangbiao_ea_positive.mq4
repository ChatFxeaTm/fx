//+------------------------------------------------------------------+
//| 汇市风向标_EA_正期望结构版.mq4                                  |
//| 基于“汇市风向标”趋势通道突破指标重构                            |
//|                                                                  |
//| 核心目标：                                                       |
//| 1. 保留原指标在盘面上的通道、信号、区间、面板显示。              |
//| 2. 将指标信号改造成 EA 自动交易逻辑。                            |
//| 3. 增加假突破过滤：最小突破距离、实体比例、ADX、ATR、EMA斜率。   |
//| 4. 增加回踩确认：突破后不急追，等待回踩确认后再进场。            |
//| 5. 使用固定风险、R倍数止盈、保本、移动止损构建正期望结构。        |
//|                                                                  |
//| 严格说明：                                                       |
//| 本 EA 不能保证盈利。所谓“正期望结构”指交易系统设计上使用          |
//| 过滤 + 盈亏比 + 风险控制，不代表未经回测和实盘验证就一定正收益。  |
//+------------------------------------------------------------------+
#property strict
#property copyright "汇市风向标 EA 汉化重构版"
#property link      "https://chatfxeatm.github.io/fx/huishi-fengxiangbiao-cn-20260702/"
#property version   "1.10"
#property description "汇市风向标 EA：通道突破 + 假突破过滤 + 回踩确认 + R倍数风控。"

//+------------------------------------------------------------------+
//| 价格源枚举                                                       |
//+------------------------------------------------------------------+
enum ENUM_HY_PRICE
{
   HY_PRICE_CLOSE = 0,              // 收盘价
   HY_PRICE_MEDIAN = 1,             // 中间价：(High + Low) / 2
   HY_PRICE_TYPICAL = 2,            // 典型价：(High + Low + Close) / 3
   HY_PRICE_WEIGHTED = 3,           // 加权收盘价：(High + Low + 2*Close) / 4
   HY_PRICE_HA_CLOSE = 4,           // 平均K线收盘价
   HY_PRICE_HA_MEDIAN = 5,          // 平均K线中间价
   HY_PRICE_HA_TYPICAL = 6,         // 平均K线典型价
   HY_PRICE_HA_WEIGHTED = 7         // 平均K线加权收盘价
};

//+------------------------------------------------------------------+
//| EA 基础参数                                                      |
//+------------------------------------------------------------------+
input string  EAName                 = "汇市风向标EA";       // EA名称/对象名前缀
input int     MagicNumber            = 20260702;             // 魔术码
input bool    EnableTrading          = true;                 // 是否允许自动交易
input bool    OnePositionOnly        = true;                 // 是否全局只允许一个持仓
input bool    CloseOnOppositeSignal  = true;                 // 出现反向确认信号时是否平掉原方向持仓
input bool    AllowReverseSameBar    = false;                // 平掉反向持仓后是否同一根K线反手
input int     MaxSpreadPoints        = 35;                   // 最大允许点差，单位：黄金标准点/内部点值
input int     SlippageBrokerPoints   = 20;                   // 下单滑点，单位：平台Point

//+------------------------------------------------------------------+
//| 指标通道参数                                                     |
//+------------------------------------------------------------------+
input string  Group_Channel          = "=== 通道与信号设置 ===";
input ENUM_HY_PRICE PriceSource      = HY_PRICE_HA_CLOSE;    // 趋势突破价格源
input int     ChannelPeriod          = 5;                    // 基础通道周期
input int     MaxChannelPeriod       = 30;                   // 最大通道周期
input double  Margin                 = 0.0;                  // 通道内缩比例
input double  MinChannelWidthPoints  = 100.0;                // 最小通道宽度，黄金建议100~150
input double  MaxChannelWidthPoints  = 1800.0;               // 最大通道宽度，过大说明止损过宽
input int     SignalLookbackBars     = 350;                  // 趋势状态计算回看K线数量

//+------------------------------------------------------------------+
//| 假突破过滤参数                                                   |
//+------------------------------------------------------------------+
input string  Group_Filter           = "=== 假突破过滤设置 ===";
input bool    UseBreakoutDistance    = true;                 // 是否启用最小突破距离过滤
input double  MinBreakoutPoints      = 35.0;                 // 最小突破距离，黄金标准点/内部点值
input bool    UseBodyFilter          = true;                 // 是否启用实体比例过滤
input double  MinBodyRatio           = 0.45;                 // 最小实体比例：实体/整根K线
input bool    RequireDirectionCandle = true;                 // 是否要求突破K线方向一致
input bool    UseADXFilter           = true;                 // 是否启用ADX趋势强度过滤
input int     ADXPeriod              = 14;                   // ADX周期
input double  MinADX                 = 18.0;                 // 最小ADX，低于该值视为震荡
input bool    UseATRFilter           = true;                 // 是否启用ATR波动过滤
input int     ATRPeriod              = 14;                   // ATR周期
input double  MinATRPoints           = 80.0;                 // 最小ATR，太低不交易
input bool    UseEMAFilter           = true;                 // 是否启用EMA斜率过滤
input int     EMAPeriod              = 144;                  // 趋势EMA周期
input int     EMASlopeBars           = 5;                    // EMA斜率对比K线距离
input double  MinEMASlopePoints      = 15.0;                 // 最小EMA斜率点数
input bool    StrictFilterMode       = true;                 // 严格模式：任一启用过滤失败则不交易
input int     MinSignalScore         = 4;                    // 非严格模式下最低信号评分

//+------------------------------------------------------------------+
//| 回踩确认参数                                                     |
//+------------------------------------------------------------------+
input string  Group_Retest           = "=== 回踩确认设置 ===";
input bool    UseRetestConfirm       = true;                 // 是否启用回踩确认
input int     RetestBars             = 3;                    // 突破后允许几根K线内回踩
input double  RetestTolerancePoints  = 30.0;                 // 回踩容忍距离
input bool    RetestMustCloseOutside = true;                 // 回踩确认K线是否必须收在通道外

//+------------------------------------------------------------------+
//| 风控与出场参数                                                   |
//+------------------------------------------------------------------+
input string  Group_Risk             = "=== 风控与出场设置 ===";
input bool    UseFixedLot            = true;                 // 是否使用固定手数
input double  FixedLot               = 0.01;                 // 固定手数
input double  RiskPercent            = 1.0;                  // 自动手数单笔风险百分比
input double  MinLotLimit            = 0.01;                 // 最小手数限制
input double  MaxLotLimit            = 1.00;                 // 最大手数限制
input double  StopBufferPoints       = 30.0;                 // 止损缓冲点数
input double  MinStopPoints          = 120.0;                // 最小止损距离
input double  MaxStopPoints          = 1200.0;               // 最大止损距离，超过不做
input double  TakeProfitR            = 1.60;                 // 止盈R倍数，必须大于1才有正期望空间
input bool    UseBreakEven           = true;                 // 是否启用保本
input double  BreakEvenStartR        = 1.00;                 // 盈利达到多少R启动保本
input double  BreakEvenLockPoints    = 5.0;                  // 保本后锁定点数
input bool    UseTrailingStop        = true;                 // 是否启用移动止损
input double  TrailStartR            = 1.20;                 // 盈利达到多少R启动移动止损
input double  TrailDistanceR         = 0.60;                 // 移动止损距离，按R计算
input int     MaxHoldingBars         = 36;                   // 最大持仓K线数，0=不限制

//+------------------------------------------------------------------+
//| 时间与安全参数                                                   |
//+------------------------------------------------------------------+
input string  Group_Safety           = "=== 交易安全设置 ===";
input bool    UseTradingTimeFilter   = false;                // 是否启用交易时段过滤
input int     TradeStartHour         = 7;                    // 允许交易开始小时，服务器时间
input int     TradeEndHour           = 23;                   // 允许交易结束小时，服务器时间
input bool    FridayStopNewTrade     = true;                 // 周五是否停止新开仓
input int     FridayStopHour         = 20;                   // 周五停止新开仓小时，服务器时间
input bool    EnableExpiryCheck      = false;                // 是否启用到期限制
input datetime ExpiryTime            = D'2029.09.30 12:00';  // 到期时间
input string  ContactInfo            = "QQ:2026904767";      // 联系方式

//+------------------------------------------------------------------+
//| 盘面显示参数                                                     |
//+------------------------------------------------------------------+
input string  Group_Display          = "=== 盘面显示设置 ===";
input bool    ShowIndicatorOnChart   = true;                 // 是否在盘面显示指标
input bool    ShowChannel            = true;                 // 是否显示通道线
input bool    ShowSignalArrows       = true;                 // 是否显示信号箭头
input bool    ShowSignalBoxes        = true;                 // 是否显示趋势区间矩形
input bool    ShowPanel              = true;                 // 是否显示EA状态面板
input int     DisplayBars            = 120;                  // 盘面绘制最近多少根通道
input color   UpTrendColor           = clrGold;              // 上升趋势颜色
input color   DnTrendColor           = clrDeepSkyBlue;       // 下跌趋势颜色
input color   BuyArrowColor          = clrRed;               // 买入箭头颜色
input color   SellArrowColor         = clrLimeGreen;         // 卖出箭头颜色
input int     BuyArrowCode           = 233;                  // 买入箭头代码
input int     SellArrowCode          = 234;                  // 卖出箭头代码
input int     ArrowSize              = 2;                    // 箭头大小
input ENUM_BASE_CORNER PanelCorner   = CORNER_LEFT_UPPER;    // 面板位置
input int     PanelX                 = 12;                   // 面板X坐标
input int     PanelY                 = 25;                   // 面板Y坐标

//+------------------------------------------------------------------+
//| 全局状态                                                         |
//+------------------------------------------------------------------+
double   g_point = 0.0;                 // 黄金标准点/内部点值：XAU三位报价通常=0.01
bool     g_tradeSwitch = true;          // 图表按钮控制的交易开关
bool     g_displaySwitch = true;        // 图表按钮控制的显示开关
datetime g_lastBarTime = 0;
string   g_prefix;
string   g_tradeButton;
string   g_displayButton;

int      g_pendingDir = 0;              // 1=等待多头回踩，-1=等待空头回踩
int      g_pendingAge = 0;
double   g_pendingLevel = 0.0;
double   g_pendingSL = 0.0;
double   g_pendingTP = 0.0;
datetime g_pendingSignalTime = 0;
string   g_pendingReason = "";

int      g_lastSignalDir = 0;
datetime g_lastSignalTime = 0;
string   g_lastSignalText = "无";
string   g_lastFilterText = "等待新K线";
string   g_statusText = "初始化";

//+------------------------------------------------------------------+
//| 初始化                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   if(EnableExpiryCheck && TimeCurrent() > ExpiryTime)
   {
      Alert(EAName + " 已到期，请联系：" + ContactInfo);
      return(INIT_FAILED);
   }

   g_point = Point * MathPow(10, Digits % 2);
   if(g_point <= 0) g_point = Point;

   g_prefix = EAName + "_" + IntegerToString(MagicNumber) + "_";
   g_tradeButton = g_prefix + "BTN_TRADE";
   g_displayButton = g_prefix + "BTN_DISPLAY";

   CreateButton(g_tradeButton, "EA交易:ON", PanelX, PanelY, 92, 20, clrDarkSlateGray, clrLime);
   CreateButton(g_displayButton, "显示:ON", PanelX + 98, PanelY, 78, 20, clrDarkSlateGray, clrLime);

   g_lastBarTime = 0;
   g_statusText = "等待新K线";

   DrawAll();
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 反初始化                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DeleteObjectsByPrefix(g_prefix);
   Comment("");
}

//+------------------------------------------------------------------+
//| 每个Tick执行                                                     |
//+------------------------------------------------------------------+
void OnTick()
{
   if(EnableExpiryCheck && TimeCurrent() > ExpiryTime)
   {
      g_statusText = "授权到期，EA停止";
      UpdatePanel();
      return;
   }

   ManageOpenPositions();

   if(IsNewBar())
   {
      OnNewBarProcess();
      if(g_displaySwitch && ShowIndicatorOnChart) DrawAll();
   }

   UpdatePanel();
}

//+------------------------------------------------------------------+
//| 图表事件：按钮开关                                               |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK) return;

   if(sparam == g_tradeButton)
   {
      g_tradeSwitch = !g_tradeSwitch;
      ObjectSetString(0, g_tradeButton, OBJPROP_TEXT, g_tradeSwitch ? "EA交易:ON" : "EA交易:OFF");
      ObjectSetInteger(0, g_tradeButton, OBJPROP_COLOR, g_tradeSwitch ? clrLime : clrTomato);
      g_statusText = g_tradeSwitch ? "交易开关已开启" : "交易开关已关闭";
   }

   if(sparam == g_displayButton)
   {
      g_displaySwitch = !g_displaySwitch;
      ObjectSetString(0, g_displayButton, OBJPROP_TEXT, g_displaySwitch ? "显示:ON" : "显示:OFF");
      ObjectSetInteger(0, g_displayButton, OBJPROP_COLOR, g_displaySwitch ? clrLime : clrTomato);
      if(!g_displaySwitch) DeleteDisplayObjectsOnly();
      else DrawAll();
   }
}

//+------------------------------------------------------------------+
//| 新K线处理：先检查回踩，再识别新突破                              |
//+------------------------------------------------------------------+
void OnNewBarProcess()
{
   if(Bars < MathMax(MaxChannelPeriod + EMASlopeBars + 10, 200))
   {
      g_statusText = "历史K线不足";
      return;
   }

   // 先处理上一轮候选信号的回踩确认。
   if(g_pendingDir != 0)
   {
      g_pendingAge++;
      if(CheckRetestConfirmed(1))
      {
         int retestDir = g_pendingDir;
         string retestText = (retestDir > 0 ? "多头回踩确认" : "空头回踩确认");
         g_lastFilterText = retestText + "，准备执行";

         if(CloseOnOppositeSignal) CloseOppositePositions(retestDir);

         if(CanOpenNewPosition(retestDir))
            OpenTrade(retestDir, g_pendingSL, retestText);

         ClearPendingSignal();
         if(!AllowReverseSameBar) return;
      }
      else if(g_pendingAge > RetestBars)
      {
         g_lastFilterText = "候选信号超时，取消回踩等待";
         ClearPendingSignal();
      }
   }

   int signalDir = 0;
   double signalLevel = 0.0;
   double signalSL = 0.0;
   string reason = "";
   int score = 0;

   if(DetectSignal(signalDir, signalLevel, signalSL, reason, score))
   {
      g_lastSignalDir = signalDir;
      g_lastSignalTime = Time[1];
      g_lastSignalText = (signalDir > 0 ? "多头突破" : "空头突破") + "，评分=" + IntegerToString(score);
      g_lastFilterText = reason;

      if(g_displaySwitch && ShowIndicatorOnChart)
         DrawSignal(signalDir, Time[1], signalLevel, reason);

      if(CloseOnOppositeSignal) CloseOppositePositions(signalDir);

      if(UseRetestConfirm)
      {
         g_pendingDir = signalDir;
         g_pendingAge = 0;
         g_pendingLevel = signalLevel;
         g_pendingSL = signalSL;
         g_pendingSignalTime = Time[1];
         g_pendingReason = reason;
         g_statusText = "候选突破，等待回踩确认";
      }
      else
      {
         if(CanOpenNewPosition(signalDir))
            OpenTrade(signalDir, signalSL, reason);
      }
   }
   else
   {
      g_statusText = "无合格新信号";
      g_lastFilterText = reason;
   }
}

//+------------------------------------------------------------------+
//| 识别突破信号                                                     |
//+------------------------------------------------------------------+
bool DetectSignal(int &dir, double &level, double &sl, string &reason, int &score)
{
   dir = 0;
   level = 0.0;
   sl = 0.0;
   score = 0;
   reason = "无趋势切换";

   int lookback = MathMin(SignalLookbackBars, Bars - MaxChannelPeriod - 5);
   if(lookback < 20)
   {
      reason = "可用历史K线不足";
      return(false);
   }

   double trendArr[];
   double upArr[];
   double loArr[];
   ArrayResize(trendArr, lookback + 3);
   ArrayResize(upArr, lookback + 3);
   ArrayResize(loArr, lookback + 3);
   ArrayInitialize(trendArr, 0.0);
   ArrayInitialize(upArr, EMPTY_VALUE);
   ArrayInitialize(loArr, EMPTY_VALUE);

   int hhbar = 0;
   int llbar = 0;

   for(int i = lookback; i >= 1; i--)
   {
      if(!CalculateChannel(i, upArr[i], loArr[i], hhbar, llbar))
      {
         trendArr[i] = trendArr[i + 1];
         continue;
      }

      trendArr[i] = trendArr[i + 1];

      if(i < lookback && upArr[i + 1] != EMPTY_VALUE && loArr[i + 1] != EMPTY_VALUE)
      {
         double p = PriceWrapper(PriceSource, i);
         if(p > upArr[i + 1]) trendArr[i] = 1;
         if(p < loArr[i + 1]) trendArr[i] = -1;
      }
   }

   if(trendArr[1] > 0 && trendArr[2] <= 0)
   {
      dir = 1;
      level = upArr[2];
      sl = loArr[1] - StopBufferPoints * g_point;
   }
   else if(trendArr[1] < 0 && trendArr[2] >= 0)
   {
      dir = -1;
      level = loArr[2];
      sl = upArr[1] + StopBufferPoints * g_point;
   }
   else
   {
      reason = "趋势未发生有效切换";
      return(false);
   }

   if(level <= 0 || sl <= 0 || level == EMPTY_VALUE || sl == EMPTY_VALUE)
   {
      reason = "通道边界无效";
      return(false);
   }

   if(!PassFilters(dir, level, sl, reason, score))
   {
      return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+
//| 假突破过滤                                                       |
//+------------------------------------------------------------------+
bool PassFilters(int dir, double level, double sl, string &reason, int &score)
{
   score = 0;
   string fail = "";

   double close1 = Close[1];
   double open1  = Open[1];
   double high1  = High[1];
   double low1   = Low[1];
   double range  = MathMax(high1 - low1, g_point);
   double body   = MathAbs(close1 - open1);
   double bodyRatio = body / range;

   double breakoutDistance = 0.0;
   if(dir > 0) breakoutDistance = (close1 - level) / g_point;
   if(dir < 0) breakoutDistance = (level - close1) / g_point;

   if(UseBreakoutDistance)
   {
      if(breakoutDistance >= MinBreakoutPoints) score++;
      else fail += "突破距离不足; ";
   }
   else score++;

   if(UseBodyFilter)
   {
      bool bodyOK = (bodyRatio >= MinBodyRatio);
      if(RequireDirectionCandle)
      {
         if(dir > 0) bodyOK = bodyOK && (close1 > open1);
         if(dir < 0) bodyOK = bodyOK && (close1 < open1);
      }
      if(bodyOK) score++;
      else fail += "实体力度不足; ";
   }
   else score++;

   if(UseADXFilter)
   {
      double adx = iADX(Symbol(), 0, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);
      if(adx >= MinADX) score++;
      else fail += "ADX趋势强度不足; ";
   }
   else score++;

   if(UseATRFilter)
   {
      double atrPoints = iATR(Symbol(), 0, ATRPeriod, 1) / g_point;
      if(atrPoints >= MinATRPoints) score++;
      else fail += "ATR波动不足; ";
   }
   else score++;

   if(UseEMAFilter)
   {
      double emaNow  = iMA(Symbol(), 0, EMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1);
      double emaPast = iMA(Symbol(), 0, EMAPeriod, 0, MODE_EMA, PRICE_CLOSE, 1 + EMASlopeBars);
      double slopePoints = (emaNow - emaPast) / g_point;
      bool emaOK = false;
      if(dir > 0) emaOK = (slopePoints >= MinEMASlopePoints);
      if(dir < 0) emaOK = (slopePoints <= -MinEMASlopePoints);
      if(emaOK) score++;
      else fail += "EMA斜率不支持方向; ";
   }
   else score++;

   double stopPoints = MathAbs((dir > 0 ? Ask : Bid) - sl) / g_point;
   if(stopPoints < MinStopPoints)
   {
      fail += "止损过小; ";
   }
   else if(stopPoints > MaxStopPoints)
   {
      fail += "止损过大; ";
   }
   else
   {
      score++;
   }

   double channelWidthPoints = 0.0;
   double up = 0.0, lo = 0.0;
   int hhbar = 0, llbar = 0;
   if(CalculateChannel(1, up, lo, hhbar, llbar))
   {
      channelWidthPoints = (up - lo) / g_point;
      if(channelWidthPoints <= MaxChannelWidthPoints) score++;
      else fail += "通道过宽; ";
   }

   if(StrictFilterMode && fail != "")
   {
      reason = fail;
      return(false);
   }

   if(!StrictFilterMode && score < MinSignalScore)
   {
      reason = "评分不足：" + IntegerToString(score) + "，" + fail;
      return(false);
   }

   reason = "过滤通过：评分=" + IntegerToString(score);
   if(fail != "") reason += "；弱项=" + fail;
   return(true);
}

//+------------------------------------------------------------------+
//| 回踩确认                                                         |
//+------------------------------------------------------------------+
bool CheckRetestConfirmed(int shift)
{
   if(g_pendingDir == 0) return(false);

   double tol = RetestTolerancePoints * g_point;

   if(g_pendingDir > 0)
   {
      bool touched = (Low[shift] <= g_pendingLevel + tol);
      bool closedOutside = (Close[shift] > g_pendingLevel);
      bool notBroken = (Close[shift] > g_pendingSL);
      if(RetestMustCloseOutside) return(touched && closedOutside && notBroken);
      return(touched && notBroken);
   }

   if(g_pendingDir < 0)
   {
      bool touched = (High[shift] >= g_pendingLevel - tol);
      bool closedOutside = (Close[shift] < g_pendingLevel);
      bool notBroken = (Close[shift] < g_pendingSL);
      if(RetestMustCloseOutside) return(touched && closedOutside && notBroken);
      return(touched && notBroken);
   }

   return(false);
}

void ClearPendingSignal()
{
   g_pendingDir = 0;
   g_pendingAge = 0;
   g_pendingLevel = 0.0;
   g_pendingSL = 0.0;
   g_pendingTP = 0.0;
   g_pendingSignalTime = 0;
   g_pendingReason = "";
}

//+------------------------------------------------------------------+
//| 计算通道                                                         |
//+------------------------------------------------------------------+
bool CalculateChannel(int shift, double &up, double &lo, int &hhbar, int &llbar)
{
   up = EMPTY_VALUE;
   lo = EMPTY_VALUE;
   hhbar = -1;
   llbar = -1;

   int minPeriod = MathMax(ChannelPeriod, 2);
   int maxPeriod = MathMax(MaxChannelPeriod, minPeriod);

   if(shift + maxPeriod + 2 >= Bars) return(false);

   double hh = 0.0;
   double ll = 0.0;
   double width = 0.0;

   for(int period = minPeriod; period <= maxPeriod; period++)
   {
      hhbar = iHighest(NULL, 0, MODE_HIGH, period, shift);
      llbar = iLowest(NULL, 0, MODE_LOW, period, shift);
      if(hhbar < 0 || llbar < 0) return(false);

      hh = High[hhbar];
      ll = Low[llbar];
      width = (hh - ll) * (1.0 - 2.0 * Margin);

      if(width >= MinChannelWidthPoints * g_point) break;
   }

   if(width <= 0) return(false);

   up = hh - width * Margin;
   lo = ll + width * Margin;

   if(up <= lo) return(false);

   return(true);
}

//+------------------------------------------------------------------+
//| 价格源封装                                                       |
//+------------------------------------------------------------------+
double PriceWrapper(ENUM_HY_PRICE priceType, int bar)
{
   switch(priceType)
   {
      case HY_PRICE_CLOSE:       return(Close[bar]);
      case HY_PRICE_MEDIAN:      return((High[bar] + Low[bar]) / 2.0);
      case HY_PRICE_TYPICAL:     return((High[bar] + Low[bar] + Close[bar]) / 3.0);
      case HY_PRICE_WEIGHTED:    return((High[bar] + Low[bar] + 2.0 * Close[bar]) / 4.0);
      case HY_PRICE_HA_CLOSE:    return(HeikenAshiValue(0, bar));
      case HY_PRICE_HA_MEDIAN:   return(HeikenAshiValue(1, bar));
      case HY_PRICE_HA_TYPICAL:  return(HeikenAshiValue(2, bar));
      case HY_PRICE_HA_WEIGHTED: return(HeikenAshiValue(3, bar));
   }
   return(Close[bar]);
}

//+------------------------------------------------------------------+
//| 平均K线价格计算                                                  |
//+------------------------------------------------------------------+
double HeikenAshiValue(int mode, int bar)
{
   int start = MathMin(Bars - 1, bar + 300);
   double prevOpen = Open[start];
   double prevClose = Close[start];
   double haOpen = prevOpen;
   double haClose = prevClose;
   double haHigh = High[start];
   double haLow = Low[start];

   for(int i = start; i >= bar; i--)
   {
      if(i == start)
      {
         haOpen = Open[i];
         haClose = Close[i];
         haHigh = High[i];
         haLow = Low[i];
      }
      else
      {
         haClose = (Open[i] + High[i] + Low[i] + Close[i]) / 4.0;
         haOpen = (prevOpen + prevClose) / 2.0;
         haHigh = MathMax(High[i], MathMax(haOpen, haClose));
         haLow = MathMin(Low[i], MathMin(haOpen, haClose));
      }

      prevOpen = haOpen;
      prevClose = haClose;
   }

   if(mode == 0) return(haClose);
   if(mode == 1) return((haHigh + haLow) / 2.0);
   if(mode == 2) return((haHigh + haLow + haClose) / 3.0);
   if(mode == 3) return((haHigh + haLow + 2.0 * haClose) / 4.0);

   return(haClose);
}

//+------------------------------------------------------------------+
//| 下单前检查                                                       |
//+------------------------------------------------------------------+
bool CanOpenNewPosition(int dir)
{
   if(!EnableTrading)
   {
      g_statusText = "参数禁止自动交易";
      return(false);
   }

   if(!g_tradeSwitch)
   {
      g_statusText = "按钮交易开关关闭";
      return(false);
   }

   if(!IsTradeAllowed())
   {
      g_statusText = "MT4未允许自动交易";
      return(false);
   }

   if(!IsTradingTimeOK())
   {
      g_statusText = "不在允许交易时段";
      return(false);
   }

   double spreadPoints = (Ask - Bid) / g_point;
   if(spreadPoints > MaxSpreadPoints)
   {
      g_statusText = "点差过大：" + DoubleToStr(spreadPoints, 1);
      return(false);
   }

   if(OnePositionOnly && CountMyPositions(0) > 0)
   {
      g_statusText = "已有持仓，等待管理";
      return(false);
   }

   if(CountMyPositions(dir) > 0)
   {
      g_statusText = "同方向已有持仓";
      return(false);
   }

   return(true);
}

bool IsTradingTimeOK()
{
   if(!UseTradingTimeFilter && !FridayStopNewTrade) return(true);

   int day = TimeDayOfWeek(TimeCurrent());
   int hour = TimeHour(TimeCurrent());

   if(FridayStopNewTrade && day == 5 && hour >= FridayStopHour)
      return(false);

   if(UseTradingTimeFilter)
   {
      if(TradeStartHour == TradeEndHour) return(true);

      if(TradeStartHour < TradeEndHour)
      {
         if(hour < TradeStartHour || hour >= TradeEndHour) return(false);
      }
      else
      {
         if(hour < TradeStartHour && hour >= TradeEndHour) return(false);
      }
   }

   return(true);
}

//+------------------------------------------------------------------+
//| 下单                                                             |
//+------------------------------------------------------------------+
bool OpenTrade(int dir, double sl, string reason)
{
   RefreshRates();

   double entry = (dir > 0 ? Ask : Bid);
   sl = NormalizeDouble(sl, Digits);

   double riskDistance = MathAbs(entry - sl);
   double riskPoints = riskDistance / g_point;

   if(riskPoints < MinStopPoints || riskPoints > MaxStopPoints)
   {
      g_statusText = "止损距离不合格：" + DoubleToStr(riskPoints, 1);
      return(false);
   }

   double tp = 0.0;
   if(dir > 0) tp = entry + riskDistance * TakeProfitR;
   if(dir < 0) tp = entry - riskDistance * TakeProfitR;

   AdjustStopsToBrokerLimit(dir, entry, sl, tp);

   double lots = CalculateLots(entry, sl);
   if(lots <= 0)
   {
      g_statusText = "手数计算失败";
      return(false);
   }

   int orderType = (dir > 0 ? OP_BUY : OP_SELL);
   color clr = (dir > 0 ? BuyArrowColor : SellArrowColor);
   string comment = "HYEA " + (dir > 0 ? "BUY" : "SELL") + " R=" + DoubleToStr(TakeProfitR, 2);

   int ticket = OrderSend(Symbol(), orderType, lots, entry, SlippageBrokerPoints, sl, tp, comment, MagicNumber, 0, clr);

   if(ticket < 0)
   {
      int err = GetLastError();
      g_statusText = "下单失败，错误码=" + IntegerToString(err);
      ResetLastError();
      return(false);
   }

   g_statusText = "已开" + (dir > 0 ? "多" : "空") + "，手数=" + DoubleToStr(lots, 2);

   if(g_displaySwitch && ShowIndicatorOnChart)
      DrawTradeArrow(dir, Time[0], entry, ticket, reason);

   return(true);
}

void AdjustStopsToBrokerLimit(int dir, double entry, double &sl, double &tp)
{
   double minStop = MarketInfo(Symbol(), MODE_STOPLEVEL) * Point;
   double freeze = MarketInfo(Symbol(), MODE_FREEZELEVEL) * Point;
   double minDistance = MathMax(minStop, freeze) + Point;

   if(dir > 0)
   {
      if(entry - sl < minDistance) sl = entry - minDistance;
      if(tp - entry < minDistance) tp = entry + minDistance;
   }
   else
   {
      if(sl - entry < minDistance) sl = entry + minDistance;
      if(entry - tp < minDistance) tp = entry - minDistance;
   }

   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);
}

//+------------------------------------------------------------------+
//| 手数计算                                                         |
//+------------------------------------------------------------------+
double CalculateLots(double entry, double sl)
{
   double lots = FixedLot;

   if(!UseFixedLot)
   {
      double riskMoney = AccountBalance() * RiskPercent / 100.0;
      double tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
      double tickSize = MarketInfo(Symbol(), MODE_TICKSIZE);
      if(tickValue <= 0 || tickSize <= 0) return(0.0);

      double riskPerLot = MathAbs(entry - sl) / tickSize * tickValue;
      if(riskPerLot <= 0) return(0.0);

      lots = riskMoney / riskPerLot;
   }

   lots = NormalizeLots(lots);
   return(lots);
}

double NormalizeLots(double lots)
{
   double minLot = MarketInfo(Symbol(), MODE_MINLOT);
   double maxLot = MarketInfo(Symbol(), MODE_MAXLOT);
   double step = MarketInfo(Symbol(), MODE_LOTSTEP);

   minLot = MathMax(minLot, MinLotLimit);
   maxLot = MathMin(maxLot, MaxLotLimit);

   if(step <= 0) step = 0.01;

   lots = MathMax(lots, minLot);
   lots = MathMin(lots, maxLot);
   lots = MathFloor(lots / step) * step;

   return(NormalizeDouble(lots, LotDigits(step)));
}

int LotDigits(double step)
{
   if(step >= 1.0) return(0);
   if(step >= 0.1) return(1);
   if(step >= 0.01) return(2);
   if(step >= 0.001) return(3);
   return(4);
}

//+------------------------------------------------------------------+
//| 持仓管理：保本、移动止损、持仓时间                               |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MagicNumber) continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL) continue;

      int dir = (OrderType() == OP_BUY ? 1 : -1);
      double open = OrderOpenPrice();
      double sl = OrderStopLoss();
      double tp = OrderTakeProfit();

      if(tp <= 0 || TakeProfitR <= 0) continue;

      double originalR = MathAbs(tp - open) / TakeProfitR;
      if(originalR <= 0) continue;

      double profitDistance = 0.0;
      if(dir > 0) profitDistance = Bid - open;
      else profitDistance = open - Ask;

      // 最大持仓K线数控制：时间到了还没走出来，说明信号效率不足，主动退出。
      if(MaxHoldingBars > 0)
      {
         int barsHeld = iBarShift(Symbol(), 0, OrderOpenTime(), false);
         if(barsHeld >= MaxHoldingBars)
         {
            CloseOrder(OrderTicket(), "超过最大持仓K线数");
            continue;
         }
      }

      // 保本：盈利达到指定R后，把止损推到开仓价附近。
      if(UseBreakEven && profitDistance >= originalR * BreakEvenStartR)
      {
         double beSL = open;
         if(dir > 0) beSL = open + BreakEvenLockPoints * g_point;
         if(dir < 0) beSL = open - BreakEvenLockPoints * g_point;
         beSL = NormalizeDouble(beSL, Digits);

         bool needBE = false;
         if(dir > 0 && (sl < beSL || sl <= 0)) needBE = true;
         if(dir < 0 && (sl > beSL || sl <= 0)) needBE = true;

         if(needBE)
            ModifyStop(OrderTicket(), beSL, tp, "保本止损");
      }

      // 移动止损：盈利达到指定R后，按R距离跟随价格。
      if(UseTrailingStop && profitDistance >= originalR * TrailStartR)
      {
         double trailSL = sl;
         if(dir > 0) trailSL = Bid - originalR * TrailDistanceR;
         if(dir < 0) trailSL = Ask + originalR * TrailDistanceR;
         trailSL = NormalizeDouble(trailSL, Digits);

         bool needTrail = false;
         if(dir > 0 && trailSL > sl && trailSL < Bid) needTrail = true;
         if(dir < 0 && (trailSL < sl || sl <= 0) && trailSL > Ask) needTrail = true;

         if(needTrail)
            ModifyStop(OrderTicket(), trailSL, tp, "移动止损");
      }
   }
}

bool ModifyStop(int ticket, double newSL, double tp, string tag)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return(false);

   double open = OrderOpenPrice();
   color clr = (OrderType() == OP_BUY ? BuyArrowColor : SellArrowColor);

   bool ok = OrderModify(ticket, open, newSL, tp, 0, clr);
   if(!ok)
   {
      int err = GetLastError();
      g_statusText = tag + "修改失败，错误码=" + IntegerToString(err);
      ResetLastError();
      return(false);
   }

   g_statusText = tag + "已更新";
   return(true);
}

//+------------------------------------------------------------------+
//| 平仓逻辑                                                         |
//+------------------------------------------------------------------+
void CloseOppositePositions(int signalDir)
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MagicNumber) continue;

      if(signalDir > 0 && OrderType() == OP_SELL)
         CloseOrder(OrderTicket(), "反向多头信号");

      if(signalDir < 0 && OrderType() == OP_BUY)
         CloseOrder(OrderTicket(), "反向空头信号");
   }
}

bool CloseOrder(int ticket, string reason)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET)) return(false);

   RefreshRates();
   double price = (OrderType() == OP_BUY ? Bid : Ask);
   color clr = (OrderType() == OP_BUY ? BuyArrowColor : SellArrowColor);

   bool ok = OrderClose(ticket, OrderLots(), price, SlippageBrokerPoints, clr);
   if(!ok)
   {
      int err = GetLastError();
      g_statusText = "平仓失败：" + reason + "，错误码=" + IntegerToString(err);
      ResetLastError();
      return(false);
   }

   g_statusText = "已平仓：" + reason;
   return(true);
}

int CountMyPositions(int dir)
{
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol() != Symbol()) continue;
      if(OrderMagicNumber() != MagicNumber) continue;

      if(dir == 0) count++;
      if(dir > 0 && OrderType() == OP_BUY) count++;
      if(dir < 0 && OrderType() == OP_SELL) count++;
   }
   return(count);
}

//+------------------------------------------------------------------+
//| 盘面绘制                                                         |
//+------------------------------------------------------------------+
void DrawAll()
{
   if(!g_displaySwitch || !ShowIndicatorOnChart) return;
   if(Bars < MaxChannelPeriod + 10) return;

   DeleteDisplayObjectsOnly();

   if(ShowChannel) DrawChannelLines();
   DrawCurrentStatusBox();
   UpdatePanel();
}

void DrawChannelLines()
{
   int barsToDraw = MathMin(DisplayBars, Bars - MaxChannelPeriod - 5);
   if(barsToDraw <= 5) return;

   for(int i = barsToDraw; i >= 2; i--)
   {
      double up1 = 0.0, lo1 = 0.0, up2 = 0.0, lo2 = 0.0;
      int hh = 0, ll = 0;
      if(!CalculateChannel(i, up1, lo1, hh, ll)) continue;
      if(!CalculateChannel(i - 1, up2, lo2, hh, ll)) continue;

      string upName = g_prefix + "DISP_CH_UP_" + IntegerToString(i);
      string loName = g_prefix + "DISP_CH_LO_" + IntegerToString(i);
      DrawTrendSegment(upName, Time[i], up1, Time[i - 1], up2, UpTrendColor, STYLE_SOLID, 1);
      DrawTrendSegment(loName, Time[i], lo1, Time[i - 1], lo2, DnTrendColor, STYLE_SOLID, 1);
   }
}

void DrawCurrentStatusBox()
{
   double up = 0.0, lo = 0.0;
   int hh = 0, ll = 0;
   if(!CalculateChannel(1, up, lo, hh, ll)) return;

   string name = g_prefix + "DISP_CUR_BOX";
   ObjectDelete(0, name);
   if(!ShowSignalBoxes) return;

   datetime t1 = Time[MathMin(DisplayBars / 4, Bars - 2)];
   datetime t2 = Time[0];
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, t1, up, t2, lo);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void DrawSignal(int dir, datetime t, double price, string text)
{
   if(!ShowSignalArrows) return;

   string name = g_prefix + "DISP_SIGNAL_" + TimeToString(t, TIME_DATE|TIME_MINUTES);
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, dir > 0 ? BuyArrowCode : SellArrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, dir > 0 ? BuyArrowColor : SellArrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, ArrowSize);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   string txtName = name + "_TXT";
   ObjectDelete(0, txtName);
   ObjectCreate(0, txtName, OBJ_TEXT, 0, t, price);
   ObjectSetString(0, txtName, OBJPROP_TEXT, dir > 0 ? "候选多" : "候选空");
   ObjectSetInteger(0, txtName, OBJPROP_COLOR, dir > 0 ? BuyArrowColor : SellArrowColor);
   ObjectSetInteger(0, txtName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, txtName, OBJPROP_HIDDEN, true);
}

void DrawTradeArrow(int dir, datetime t, double price, int ticket, string reason)
{
   string name = g_prefix + "DISP_TRADE_" + IntegerToString(ticket);
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_ARROW, 0, t, price);
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, dir > 0 ? BuyArrowCode : SellArrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, dir > 0 ? BuyArrowColor : SellArrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, ArrowSize + 1);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);

   string txt = name + "_TXT";
   ObjectDelete(0, txt);
   ObjectCreate(0, txt, OBJ_TEXT, 0, t, price);
   ObjectSetString(0, txt, OBJPROP_TEXT, dir > 0 ? "EA买入" : "EA卖出");
   ObjectSetInteger(0, txt, OBJPROP_COLOR, dir > 0 ? BuyArrowColor : SellArrowColor);
   ObjectSetInteger(0, txt, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, txt, OBJPROP_HIDDEN, true);
}

void DrawTrendSegment(string name, datetime t1, double p1, datetime t2, double p2, color clr, int style, int width)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2);
   ObjectSetInteger(0, name, OBJPROP_RAY, false);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| 面板                                                             |
//+------------------------------------------------------------------+
void UpdatePanel()
{
   if(!ShowPanel || !g_displaySwitch) return;

   double spreadPoints = (Ask - Bid) / g_point;
   double adx = iADX(Symbol(), 0, ADXPeriod, PRICE_CLOSE, MODE_MAIN, 1);
   double atrPoints = iATR(Symbol(), 0, ATRPeriod, 1) / g_point;

   string pending = "无";
   if(g_pendingDir != 0)
      pending = (g_pendingDir > 0 ? "等待多头回踩" : "等待空头回踩") + "，剩余" + IntegerToString(MathMax(0, RetestBars - g_pendingAge)) + "根";

   string posText = "无持仓";
   int posCount = CountMyPositions(0);
   if(posCount > 0) posText = "持仓数=" + IntegerToString(posCount);

   int y = PanelY + 26;
   DrawLabel(g_prefix + "PANEL_0", EAName + "  v1.10", PanelX, y, clrGold, 10); y += 17;
   DrawLabel(g_prefix + "PANEL_1", "交易状态：" + (EnableTrading && g_tradeSwitch ? "允许" : "关闭") + " | 显示：" + (g_displaySwitch ? "开启" : "关闭"), PanelX, y, clrWhite, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_2", "点差：" + DoubleToStr(spreadPoints, 1) + " / 限制：" + IntegerToString(MaxSpreadPoints), PanelX, y, spreadPoints <= MaxSpreadPoints ? clrLime : clrTomato, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_3", "ADX：" + DoubleToStr(adx, 1) + " | ATR：" + DoubleToStr(atrPoints, 1), PanelX, y, clrSilver, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_4", "最近信号：" + g_lastSignalText, PanelX, y, clrSilver, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_5", "过滤结果：" + g_lastFilterText, PanelX, y, clrSilver, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_6", "候选状态：" + pending, PanelX, y, clrSilver, 9); y += 16;
   DrawLabel(g_prefix + "PANEL_7", "订单状态：" + posText + " | " + g_statusText, PanelX, y, clrSilver, 9);
}

void DrawLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   if(ObjectFind(0, name) < 0)
   {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, PanelCorner);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetString(0, name, OBJPROP_FONT, "Microsoft YaHei");
   }
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void CreateButton(string name, string text, int x, int y, int w, int h, color bg, color txt)
{
   ObjectDelete(0, name);
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, PanelCorner);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_COLOR, txt);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrBlack);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| 对象清理                                                         |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(string prefix)
{
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, prefix, 0) == 0)
         ObjectDelete(0, name);
   }
}

void DeleteDisplayObjectsOnly()
{
   string displayPrefix = g_prefix + "DISP_";
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      if(StringFind(name, displayPrefix, 0) == 0)
         ObjectDelete(0, name);
   }
}

//+------------------------------------------------------------------+
//| 新K线判断                                                        |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   if(Time[0] != g_lastBarTime)
   {
      g_lastBarTime = Time[0];
      return(true);
   }
   return(false);
}

//+------------------------------------------------------------------+
//| 辅助显示                                                         |
//+------------------------------------------------------------------+
string PriceSourceText()
{
   switch(PriceSource)
   {
      case HY_PRICE_CLOSE:       return("收盘价");
      case HY_PRICE_MEDIAN:      return("中间价");
      case HY_PRICE_TYPICAL:     return("典型价");
      case HY_PRICE_WEIGHTED:    return("加权收盘价");
      case HY_PRICE_HA_CLOSE:    return("平均K线收盘价");
      case HY_PRICE_HA_MEDIAN:   return("平均K线中间价");
      case HY_PRICE_HA_TYPICAL:  return("平均K线典型价");
      case HY_PRICE_HA_WEIGHTED: return("平均K线加权收盘价");
   }
   return("未知价格源");
}
//+------------------------------------------------------------------+
