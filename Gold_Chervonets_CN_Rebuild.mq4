//+------------------------------------------------------------------+
//| Gold Chervonets CN Rebuild                                      |
//| 公开资料清洁重写版，不是反编译源码，不保证与原版逐笔一致。       |
//+------------------------------------------------------------------+
#property strict
#property copyright "Clean-room rebuild for local research"
#property link      "https://spekuliantas.com/forex-robotas-gold-chervonets/"
#property version   "1.01"
#property description "基于公开资料重写的黄金 M15 双系统 EA。"

input string 参数组_优化与保护 = "===== 优化与保护设置 =====";          // ===== 优化与保护设置 =====
input double 净值停止百分比 = 90.0;                                     // 净值低于余额百分比时停止开新单
input int    优化最少交易次数 = 300;                                    // 优化用最少交易次数提示
input int    连续亏损上限 = 10;                                        // 连续亏损次数上限

input string 参数组_主设置 = "===== 主设置 =====";                      // ===== 主设置 =====
input bool   每跳检测信号 = true;                                      // 每个跳动都检测信号
input int    最大滑点旧点 = 20;                                        // 最大允许滑点，单位旧点
input bool   自动GMT偏移 = false;                                      // 自动计算服务器 GMT 偏移
input int    手动GMT偏移 = 2;                                          // 手动 GMT 偏移
input bool   使用夏令时 = true;                                        // 使用夏令时偏移
input bool   允许对冲 = true;                                          // 允许对冲持仓
input int    挂单距离 = 10;                                            // 挂单距离，0 为市价，正数限价，负数止损挂单
input int    挂单过期分钟 = 360;                                       // 挂单过期分钟数
input string 订单注释 = "金叶子重写版";                                // 订单注释

input string 参数组_过滤时间 = "===== 过滤与时间设置 =====";            // ===== 过滤与时间设置 =====
input bool   显示信息面板 = true;                                      // 显示图表信息面板
input int    最大点差旧点 = 40;                                        // 最大允许点差，单位旧点
input int    最大总订单数 = 0;                                        // 两套系统最大订单数，0 为不限制
input double 最大账户回撤百分比 = 0.0;                                 // 最大账户回撤百分比，0 为关闭
input int    ATR周期 = 14;                                             // ATR 周期
input int    ATR最低旧点 = 45;                                         // ATR 最低波动阈值，单位旧点
input int    亏损后暂停小时 = 0;                                       // 亏损后暂停小时数
input int    周一开始小时 = 0;                                        // 周一开始交易小时
input bool   周五平全部订单 = false;                                   // 周五到点平掉全部订单
input int    周五平仓小时 = 20;                                        // 周五强制平仓小时
input int    周五最后开仓小时 = 19;                                    // 周五最后开仓小时，-1 为关闭

input string 参数组_系统一主 = "===== 系统一主设置 =====";              // ===== 系统一主设置 =====
input bool   系统一启用 = true;                                        // 启用系统一
input bool   系统一只做多 = false;                                     // 系统一只允许做多
input int    系统一魔术号 = 141001;                                    // 系统一魔术号
input int    系统一止损旧点 = 2830;                                    // 系统一止损，单位旧点
input int    系统一止盈旧点 = 450;                                     // 系统一止盈，单位旧点

input string 参数组_系统一指标 = "===== 系统一指标设置 =====";          // ===== 系统一指标设置 =====
input int    系统一MA周期 = 55;                                        // 系统一 MA 周期
input int    系统一WPR周期 = 14;                                       // 系统一 WPR 周期
input int    系统一CCI周期 = 14;                                       // 系统一 CCI 周期
input int    系统一MA偏移一 = 0;                                       // 系统一 MA 偏移一，单位旧点
input int    系统一MA偏移二 = 0;                                       // 系统一 MA 偏移二，单位旧点
input double 系统一WPR入场上沿 = -20.0;                                // 系统一 WPR 入场上沿
input double 系统一WPR辅助上沿 = -20.0;                                // 系统一 WPR 辅助上沿
input double 系统一CCI阈值 = 100.0;                                    // 系统一 CCI 阈值
input int    系统一收盘回撤旧点 = 0;                                   // 系统一上一根收盘价回撤距离，单位旧点

input string 参数组_系统一平仓 = "===== 系统一跟踪与平仓 =====";        // ===== 系统一跟踪与平仓 =====
input int    系统一追踪启动旧点 = 150;                                 // 系统一启动追踪止损盈利距离，单位旧点
input int    系统一追踪距离旧点 = 50;                                  // 系统一追踪止损距离，单位旧点
input double 系统一WPR平仓上沿 = -20.0;                                // 系统一 WPR 平仓上沿
input int    系统一平仓收盘偏移 = 0;                                   // 系统一平仓收盘价偏移，单位旧点
input int    系统一平仓距离一 = 80;                                    // 系统一平仓距离一，单位旧点
input int    系统一平仓距离二 = 150;                                   // 系统一平仓距离二，单位旧点
input int    系统一M1平仓偏移 = 0;                                     // 系统一 M1 蜡烛平仓偏移，单位旧点

input string 参数组_系统一仓位 = "===== 系统一仓位管理 =====";          // ===== 系统一仓位管理 =====
input bool   系统一恢复模式 = false;                                   // 系统一恢复模式
input double 系统一固定手数 = 0.10;                                    // 系统一固定手数
input double 系统一风险百分比 = 0.0;                                   // 系统一风险百分比，0 为固定手数

input string 参数组_系统二主 = "===== 系统二主设置 =====";              // ===== 系统二主设置 =====
input bool   系统二启用 = true;                                        // 启用系统二
input int    系统二魔术号 = 142002;                                    // 系统二魔术号
input int    系统二止损旧点 = 700;                                     // 系统二止损，单位旧点
input int    系统二止盈旧点 = 0;                                       // 系统二止盈，0 为不用硬止盈
input int    系统二加仓数量 = 0;                                       // 系统二允许加仓订单数，0 为不加仓
input int    系统二加仓间距 = 250;                                     // 系统二加仓最小间距，单位旧点

input string 参数组_系统二指标 = "===== 系统二指标设置 =====";          // ===== 系统二指标设置 =====
input int    系统二随机K周期 = 5;                                      // 系统二随机指标 K 周期
input int    系统二随机D周期 = 3;                                      // 系统二随机指标 D 周期
input int    系统二随机慢化 = 3;                                      // 系统二随机指标慢化
input double 系统二随机超卖水平 = 10.0;                                // 系统二随机指标超卖水平
input int    系统二布林周期一 = 20;                                    // 系统二布林带周期一
input int    系统二布林周期三 = 20;                                    // 系统二布林带周期三
input double 系统二布林偏差 = 2.0;                                     // 系统二布林带偏差
input int    系统二布林偏移一 = 0;                                     // 系统二布林带通道偏移一，单位旧点
input int    系统二布林偏移三 = 0;                                     // 系统二布林带通道偏移三，单位旧点

input string 参数组_系统二开仓 = "===== 系统二开仓与跟踪 =====";        // ===== 系统二开仓与跟踪 =====
input int    系统二条件一二开始小时 = 0;                               // 系统二条件一二开始小时
input int    系统二条件一二结束小时 = 23;                              // 系统二条件一二结束小时
input int    系统二条件三开始小时 = 0;                                 // 系统二条件三开始小时
input int    系统二条件三结束小时 = 23;                                // 系统二条件三结束小时
input int    系统二追踪修改小时 = -1;                                  // 系统二追踪修改小时，-1 为任意小时
input int    系统二H1低点偏移 = 0;                                     // 系统二 H1 低点偏移，单位旧点
input int    系统二追踪距离旧点 = 120;                                 // 系统二追踪止损距离，单位旧点

input string 参数组_系统二平仓 = "===== 系统二平仓设置 =====";          // ===== 系统二平仓设置 =====
input int    系统二固定小时平仓 = -1;                                  // 系统二按固定小时平仓，-1 为关闭
input int    系统二平仓二开始小时 = 0;                                 // 系统二平仓条件二开始小时
input int    系统二平仓二结束小时 = 23;                                // 系统二平仓条件二结束小时
input int    系统二平仓距离二 = 120;                                   // 系统二平仓距离二，单位旧点
input int    系统二平仓距离三 = 180;                                   // 系统二平仓距离三，单位旧点
input int    系统二保本平仓距离 = 80;                                  // 系统二组合保本平仓距离，单位旧点

input string 参数组_系统二仓位 = "===== 系统二仓位管理 =====";          // ===== 系统二仓位管理 =====
input bool   系统二恢复模式 = false;                                   // 系统二恢复模式
input double 系统二固定手数 = 0.10;                                    // 系统二固定手数
input double 系统二风险百分比 = 0.0;                                   // 系统二风险百分比，0 为固定手数
input double 系统二加仓手数倍数 = 1.30;                                // 系统二加仓手数倍数

input string 参数组_新闻过滤 = "===== 新闻过滤设置 =====";              // ===== 新闻过滤设置 =====
input bool   启用新闻过滤 = false;                                     // 启用手动新闻过滤
input int    新闻前停止分钟 = 30;                                      // 新闻前停止交易分钟数
input int    新闻后恢复分钟 = 30;                                      // 新闻后恢复交易分钟数
input string 手动新闻时间列表 = "";                                   // 手动新闻时间，格式 yyyy.mm.dd hh:mi;yyyy.mm.dd hh:mi

datetime 上次检测分钟 = 0;
datetime 系统一上次开仓K线 = 0;
datetime 系统二上次开仓K线 = 0;

//+------------------------------------------------------------------+
//| 初始化                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Period() != PERIOD_M15)
      Print("建议把本 EA 挂在 M15 周期。当前周期=", Period());

   if(StringFind(Symbol(), "XAU") < 0 && StringFind(Symbol(), "GOLD") < 0)
      Print("公开资料显示原策略用于 XAUUSD。当前品种=", Symbol());

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| 退出                                                             |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
}

//+------------------------------------------------------------------+
//| 主循环                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   RefreshRates();

   处理周五离场();
   管理系统一订单();
   管理系统二订单();

   bool 允许检测 = true;
   if(!每跳检测信号)
   {
      datetime 当前分钟 = TimeCurrent() - TimeSeconds(TimeCurrent());
      if(当前分钟 == 上次检测分钟)
         允许检测 = false;
      else
         上次检测分钟 = 当前分钟;
   }

   if(允许检测 && 允许开新订单())
   {
      尝试系统一开仓();
      尝试系统二开仓();
   }

   if(显示信息面板)
      绘制信息面板();
}

//+------------------------------------------------------------------+
//| 旧点大小                                                         |
//+------------------------------------------------------------------+
double 旧点()
{
   if(StringFind(Symbol(), "XAU") >= 0 || StringFind(Symbol(), "GOLD") >= 0)
      return(0.01);
   if(Digits == 3 || Digits == 5)
      return(Point * 10.0);
   return(Point);
}

double 旧点转价格(double 点数)
{
   return(点数 * 旧点());
}

int 旧点转终端点数(double 点数)
{
   return((int)MathMax(0, MathRound(旧点转价格(点数) / Point)));
}

double 标准化价格(double 价格)
{
   return(NormalizeDouble(价格, Digits));
}

int 当前小时()
{
   return(TimeHour(TimeCurrent()));
}

int 当前GMT偏移()
{
   if(自动GMT偏移)
      return((int)MathRound((TimeCurrent() - TimeGMT()) / 3600.0));

   int 偏移 = 手动GMT偏移;
   if(使用夏令时)
      偏移++;
   return(偏移);
}

bool 小时在范围内(int 小时, int 开始, int 结束)
{
   if(开始 < 0 || 结束 < 0)
      return(false);

   开始 = MathMax(0, MathMin(23, 开始));
   结束 = MathMax(0, MathMin(23, 结束));

   if(开始 <= 结束)
      return(小时 >= 开始 && 小时 <= 结束);

   return(小时 >= 开始 || 小时 <= 结束);
}

//+------------------------------------------------------------------+
//| 新开仓过滤                                                       |
//+------------------------------------------------------------------+
bool 允许开新订单()
{
   if(!IsTradeAllowed())
      return(false);

   int 星期 = TimeDayOfWeek(TimeCurrent());
   int 小时 = 当前小时();

   if(星期 == 1 && 小时 < 周一开始小时)
      return(false);
   if(星期 == 5 && 周五最后开仓小时 >= 0 && 小时 > 周五最后开仓小时)
      return(false);

   if(最大点差旧点 > 0 && (Ask - Bid) / 旧点() > 最大点差旧点)
      return(false);

   if(最大总订单数 > 0 && 统计全部策略订单() >= 最大总订单数)
      return(false);

   if(最大账户回撤百分比 > 0.0 && AccountBalance() > 0.0)
   {
      double 回撤 = (AccountBalance() - AccountEquity()) / AccountBalance() * 100.0;
      if(回撤 >= 最大账户回撤百分比)
         return(false);
   }

   if(净值停止百分比 > 0.0 && AccountBalance() > 0.0)
   {
      double 净值百分比 = AccountEquity() / AccountBalance() * 100.0;
      if(净值百分比 <= 净值停止百分比)
         return(false);
   }

   if(亏损后暂停小时 > 0)
   {
      datetime 最近亏损 = 最近亏损平仓时间();
      if(最近亏损 > 0 && TimeCurrent() - 最近亏损 < 亏损后暂停小时 * 3600)
         return(false);
   }

   if(连续亏损上限 > 0)
   {
      if(连续亏损次数(系统一魔术号) >= 连续亏损上限)
         return(false);
      if(连续亏损次数(系统二魔术号) >= 连续亏损上限)
         return(false);
   }

   double 当前ATR = iATR(Symbol(), PERIOD_M15, ATR周期, 1);
   if(ATR最低旧点 > 0 && 当前ATR < 旧点转价格(ATR最低旧点))
      return(false);

   if(启用新闻过滤 && 处于手动新闻时间())
      return(false);

   return(true);
}

bool 处于手动新闻时间()
{
   if(StringLen(手动新闻时间列表) < 10)
      return(false);

   string 列表[];
   int 总数 = StringSplit(手动新闻时间列表, ';', 列表);
   for(int i = 0; i < 总数; i++)
   {
      string 文本 = StringTrimLeft(StringTrimRight(列表[i]));
      datetime 新闻时间 = StrToTime(文本);
      if(新闻时间 <= 0)
         continue;

      datetime 开始 = 新闻时间 - 新闻前停止分钟 * 60;
      datetime 结束 = 新闻时间 + 新闻后恢复分钟 * 60;
      if(TimeCurrent() >= 开始 && TimeCurrent() <= 结束)
         return(true);
   }

   return(false);
}

//+------------------------------------------------------------------+
//| 系统一                                                           |
//+------------------------------------------------------------------+
void 尝试系统一开仓()
{
   if(!系统一启用)
      return;
   if(Time[0] == 系统一上次开仓K线)
      return;
   if(统计魔术号订单(系统一魔术号, -1, true) > 0)
      return;

   bool 买入信号 = 系统一买入信号();
   bool 卖出信号 = (!系统一只做多 && 系统一卖出信号());

   if(买入信号 && 对冲规则允许(OP_BUY))
   {
      double 手数 = 计算手数(系统一魔术号, 系统一固定手数, 系统一风险百分比,
                          系统一止损旧点, 系统一恢复模式, 0);
      if(发送订单(OP_BUY, 手数, 系统一止损旧点, 系统一止盈旧点, 系统一魔术号, "系统一买入"))
         系统一上次开仓K线 = Time[0];
   }
   else if(卖出信号 && 对冲规则允许(OP_SELL))
   {
      double 手数 = 计算手数(系统一魔术号, 系统一固定手数, 系统一风险百分比,
                          系统一止损旧点, 系统一恢复模式, 0);
      if(发送订单(OP_SELL, 手数, 系统一止损旧点, 系统一止盈旧点, 系统一魔术号, "系统一卖出"))
         系统一上次开仓K线 = Time[0];
   }
}

bool 系统一买入信号()
{
   double 均线 = iMA(Symbol(), PERIOD_M15, 系统一MA周期, 0, MODE_SMA, PRICE_CLOSE, 1);
   double WPR = iWPR(Symbol(), PERIOD_M15, 系统一WPR周期, 1);
   double CCI = iCCI(Symbol(), PERIOD_M15, 系统一CCI周期, PRICE_TYPICAL, 1);

   bool 价格在均线上 = Close[1] > 均线 + 旧点转价格(系统一MA偏移一);
   bool 有回撤 = Close[1] > Ask + 旧点转价格(系统一收盘回撤旧点);
   bool 当前仍偏强 = Ask > 均线 + 旧点转价格(系统一MA偏移二);
   bool 震荡超卖 = (WPR <= WPR下沿(系统一WPR入场上沿)
                  || WPR <= WPR下沿(系统一WPR辅助上沿)
                  || CCI <= -MathAbs(系统一CCI阈值));

   return(价格在均线上 && 有回撤 && 当前仍偏强 && 震荡超卖);
}

bool 系统一卖出信号()
{
   double 均线 = iMA(Symbol(), PERIOD_M15, 系统一MA周期, 0, MODE_SMA, PRICE_CLOSE, 1);
   double WPR = iWPR(Symbol(), PERIOD_M15, 系统一WPR周期, 1);
   double CCI = iCCI(Symbol(), PERIOD_M15, 系统一CCI周期, PRICE_TYPICAL, 1);

   bool 价格在均线下 = Close[1] < 均线 - 旧点转价格(系统一MA偏移一);
   bool 有回撤 = Close[1] < Bid - 旧点转价格(系统一收盘回撤旧点);
   bool 当前仍偏弱 = Bid < 均线 - 旧点转价格(系统一MA偏移二);
   bool 震荡超买 = (WPR >= 系统一WPR入场上沿
                  || WPR >= 系统一WPR辅助上沿
                  || CCI >= MathAbs(系统一CCI阈值));

   return(价格在均线下 && 有回撤 && 当前仍偏弱 && 震荡超买);
}

double WPR下沿(double 上沿)
{
   return(-100.0 - 上沿);
}

void 管理系统一订单()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 系统一魔术号)
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;

      追踪当前订单(系统一追踪启动旧点, 系统一追踪距离旧点);

      if(系统一需要平仓())
         平掉当前订单("系统一信号平仓");
   }
}

bool 系统一需要平仓()
{
   double WPR = iWPR(Symbol(), PERIOD_M15, 系统一WPR周期, 1);
   double M15收盘 = iClose(Symbol(), PERIOD_M15, 1);
   double M1开盘 = iOpen(Symbol(), PERIOD_M1, 1);
   double M1收盘 = iClose(Symbol(), PERIOD_M1, 1);
   double 盈利旧点 = 当前订单盈利旧点();

   if(OrderType() == OP_BUY)
   {
      bool 条件一 = WPR >= 系统一WPR平仓上沿
                 && M15收盘 < Bid - 旧点转价格(系统一平仓收盘偏移)
                 && 盈利旧点 <= 系统一平仓距离一;
      bool 条件二 = M1收盘 < M1开盘 - 旧点转价格(系统一M1平仓偏移)
                 && 盈利旧点 >= 系统一平仓距离二;
      return(条件一 || 条件二);
   }

   if(OrderType() == OP_SELL)
   {
      bool 条件一 = WPR <= WPR下沿(系统一WPR平仓上沿)
                 && M15收盘 > Ask + 旧点转价格(系统一平仓收盘偏移)
                 && 盈利旧点 <= 系统一平仓距离一;
      bool 条件二 = M1收盘 > M1开盘 + 旧点转价格(系统一M1平仓偏移)
                 && 盈利旧点 >= 系统一平仓距离二;
      return(条件一 || 条件二);
   }

   return(false);
}

//+------------------------------------------------------------------+
//| 系统二                                                           |
//+------------------------------------------------------------------+
void 尝试系统二开仓()
{
   if(!系统二启用)
      return;
   if(Time[0] == 系统二上次开仓K线)
      return;
   if(!对冲规则允许(OP_BUY))
      return;

   int 当前订单数 = 统计魔术号订单(系统二魔术号, -1, true);
   int 允许总数 = 1 + MathMax(0, 系统二加仓数量);
   if(当前订单数 >= 允许总数)
      return;
   if(当前订单数 > 0 && !系统二允许加仓())
      return;
   if(!系统二买入信号())
      return;

   double 手数 = 计算手数(系统二魔术号, 系统二固定手数, 系统二风险百分比,
                       系统二止损旧点, 系统二恢复模式, 当前订单数);
   if(发送订单(OP_BUY, 手数, 系统二止损旧点, 系统二止盈旧点, 系统二魔术号, "系统二买入"))
      系统二上次开仓K线 = Time[0];
}

bool 系统二买入信号()
{
   int 小时 = 当前小时();

   double 随机值 = iStochastic(Symbol(), PERIOD_M15, 系统二随机K周期, 系统二随机D周期,
                              系统二随机慢化, MODE_SMA, 0, MODE_MAIN, 1);
   double 布林下轨一 = iBands(Symbol(), PERIOD_M15, 系统二布林周期一, 系统二布林偏差,
                              0, PRICE_CLOSE, MODE_LOWER, 1);
   double 布林下轨三 = iBands(Symbol(), PERIOD_M15, 系统二布林周期三, 系统二布林偏差,
                              0, PRICE_CLOSE, MODE_LOWER, 1);

   bool 条件一 = 小时在范围内(小时, 系统二条件一二开始小时, 系统二条件一二结束小时)
              && 随机值 <= 系统二随机超卖水平
              && Bid > 布林下轨一 + 旧点转价格(系统二布林偏移一);

   double H1低点 = iLow(Symbol(), PERIOD_H1, 1);
   double H1收盘 = iClose(Symbol(), PERIOD_H1, 1);
   bool 条件二 = 小时在范围内(小时, 系统二条件一二开始小时, 系统二条件一二结束小时)
              && H1低点 + 旧点转价格(系统二H1低点偏移) <= H1收盘;

   bool 条件三 = 小时在范围内(小时, 系统二条件三开始小时, 系统二条件三结束小时)
              && Bid > 布林下轨三 + 旧点转价格(系统二布林偏移三);

   return(条件一 || 条件二 || 条件三);
}

bool 系统二允许加仓()
{
   double 最近价格 = 最近开仓价(系统二魔术号, OP_BUY);
   if(最近价格 <= 0.0)
      return(true);

   return(Ask <= 最近价格 - 旧点转价格(系统二加仓间距));
}

void 管理系统二订单()
{
   bool 组合保本平仓 = (系统二保本平仓距离 > 0 && 系统二组合盈利旧点() >= 系统二保本平仓距离);

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 系统二魔术号)
         continue;
      if(OrderType() != OP_BUY)
         continue;

      if(系统二追踪修改小时 < 0 || 当前小时() == 系统二追踪修改小时)
         追踪当前订单(0, 系统二追踪距离旧点);

      if(组合保本平仓 || 系统二需要平仓())
         平掉当前订单("系统二信号平仓");
   }
}

bool 系统二需要平仓()
{
   int 小时 = 当前小时();
   double 盈利旧点 = 当前订单盈利旧点();

   bool 条件一 = (系统二固定小时平仓 >= 0 && 小时 == 系统二固定小时平仓);
   bool 条件二 = 小时在范围内(小时, 系统二平仓二开始小时, 系统二平仓二结束小时)
              && 盈利旧点 >= 系统二平仓距离二;
   bool 条件三 = 盈利旧点 >= 系统二平仓距离三
              && iClose(Symbol(), PERIOD_M15, 1) < iOpen(Symbol(), PERIOD_M15, 1);

   return(条件一 || 条件二 || 条件三);
}

//+------------------------------------------------------------------+
//| 下单与仓位                                                       |
//+------------------------------------------------------------------+
bool 发送订单(int 方向, double 手数, int 止损旧点, int 止盈旧点, int 魔术号, string 原因)
{
   if(手数 <= 0.0)
      return(false);

   RefreshRates();

   int 发送类型 = 方向;
   double 开仓价 = (方向 == OP_BUY ? Ask : Bid);
   double 距离 = 旧点转价格(MathAbs(挂单距离));

   if(挂单距离 != 0)
   {
      if(方向 == OP_BUY)
      {
         发送类型 = (挂单距离 > 0 ? OP_BUYLIMIT : OP_BUYSTOP);
         开仓价 = (挂单距离 > 0 ? Ask - 距离 : Ask + 距离);
      }
      else
      {
         发送类型 = (挂单距离 > 0 ? OP_SELLLIMIT : OP_SELLSTOP);
         开仓价 = (挂单距离 > 0 ? Bid + 距离 : Bid - 距离);
      }
   }

   开仓价 = 标准化价格(开仓价);
   double 止损 = 生成止损(方向, 开仓价, 止损旧点);
   double 止盈 = 生成止盈(方向, 开仓价, 止盈旧点);
   datetime 过期 = 0;
   if(挂单距离 != 0 && 挂单过期分钟 > 0)
      过期 = TimeCurrent() + 挂单过期分钟 * 60;

   int 票号 = OrderSend(Symbol(), 发送类型, 手数, 开仓价, 旧点转终端点数(最大滑点旧点),
                        止损, 止盈, 订单注释 + " " + 原因, 魔术号, 过期, clrGold);
   if(票号 < 0)
   {
      int 错误码 = GetLastError();
      Print("下单失败，错误码=", 错误码, " 类型=", 发送类型, " 手数=", DoubleToString(手数, 2));
      ResetLastError();
      return(false);
   }

   return(true);
}

double 生成止损(int 方向, double 开仓价, int 止损旧点)
{
   if(止损旧点 <= 0)
      return(0.0);

   if(方向 == OP_BUY)
      return(标准化价格(开仓价 - 旧点转价格(止损旧点)));

   return(标准化价格(开仓价 + 旧点转价格(止损旧点)));
}

double 生成止盈(int 方向, double 开仓价, int 止盈旧点)
{
   if(止盈旧点 <= 0)
      return(0.0);

   if(方向 == OP_BUY)
      return(标准化价格(开仓价 + 旧点转价格(止盈旧点)));

   return(标准化价格(开仓价 - 旧点转价格(止盈旧点)));
}

double 计算手数(int 魔术号, double 固定手数, double 风险百分比, int 止损旧点, bool 恢复模式, int 订单序号)
{
   double 手数 = 固定手数;

   if(风险百分比 > 0.0 && 止损旧点 > 0)
   {
      double 风险金额 = AccountBalance() * 风险百分比 / 100.0;
      double 跳动价值 = MarketInfo(Symbol(), MODE_TICKVALUE);
      double 跳动大小 = MarketInfo(Symbol(), MODE_TICKSIZE);
      double 每手亏损 = 0.0;

      if(跳动价值 > 0.0 && 跳动大小 > 0.0)
         每手亏损 = 旧点转价格(止损旧点) / 跳动大小 * 跳动价值;

      if(每手亏损 > 0.0)
         手数 = 风险金额 / 每手亏损;
   }

   if(恢复模式)
   {
      int 次数 = 连续亏损次数(魔术号);
      if(连续亏损上限 > 0)
         次数 = MathMin(次数, 连续亏损上限);
      手数 *= MathPow(1.50, 次数);
   }

   if(魔术号 == 系统二魔术号 && 订单序号 > 0)
      手数 *= MathPow(系统二加仓手数倍数, 订单序号);

   return(标准化手数(手数));
}

double 标准化手数(double 手数)
{
   double 最小手 = MarketInfo(Symbol(), MODE_MINLOT);
   double 最大手 = MarketInfo(Symbol(), MODE_MAXLOT);
   double 步进 = MarketInfo(Symbol(), MODE_LOTSTEP);

   if(步进 <= 0.0)
      步进 = 0.01;

   手数 = MathMax(最小手, MathMin(最大手, 手数));
   手数 = MathFloor(手数 / 步进 + 0.0000001) * 步进;

   return(NormalizeDouble(手数, 2));
}

bool 对冲规则允许(int 方向)
{
   if(允许对冲)
      return(true);

   int 反向 = (方向 == OP_BUY ? OP_SELL : OP_BUY);
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol())
         continue;
      if(!是策略魔术号(OrderMagicNumber()))
         continue;
      if(OrderType() == 反向)
         return(false);
   }

   return(true);
}

//+------------------------------------------------------------------+
//| 订单维护                                                         |
//+------------------------------------------------------------------+
void 追踪当前订单(int 启动旧点, int 距离旧点)
{
   if(距离旧点 <= 0)
      return;
   if(当前订单盈利旧点() < 启动旧点)
      return;

   if(OrderType() == OP_BUY)
   {
      double 新止损 = 标准化价格(Bid - 旧点转价格(距离旧点));
      if(OrderStopLoss() <= 0.0 || 新止损 > OrderStopLoss() + Point)
         修改当前订单(新止损, OrderTakeProfit());
   }
   else if(OrderType() == OP_SELL)
   {
      double 新止损 = 标准化价格(Ask + 旧点转价格(距离旧点));
      if(OrderStopLoss() <= 0.0 || 新止损 < OrderStopLoss() - Point)
         修改当前订单(新止损, OrderTakeProfit());
   }
}

bool 修改当前订单(double 止损, double 止盈)
{
   bool 成功 = OrderModify(OrderTicket(), OrderOpenPrice(), 止损, 止盈, OrderExpiration(), clrDodgerBlue);
   if(!成功)
   {
      int 错误码 = GetLastError();
      Print("修改订单失败，票号=", OrderTicket(), " 错误码=", 错误码);
      ResetLastError();
   }
   return(成功);
}

bool 平掉当前订单(string 原因)
{
   RefreshRates();
   double 平仓价 = (OrderType() == OP_BUY ? Bid : Ask);
   bool 成功 = OrderClose(OrderTicket(), OrderLots(), 平仓价, 旧点转终端点数(最大滑点旧点), clrTomato);
   if(!成功)
   {
      int 错误码 = GetLastError();
      Print(原因, " 失败，票号=", OrderTicket(), " 错误码=", 错误码);
      ResetLastError();
   }
   return(成功);
}

void 处理周五离场()
{
   if(!周五平全部订单)
      return;
   if(TimeDayOfWeek(TimeCurrent()) != 5 || 当前小时() < 周五平仓小时)
      return;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol())
         continue;
      if(!是策略魔术号(OrderMagicNumber()))
         continue;
      if(TimeCurrent() - OrderOpenTime() < 180)
         continue;

      if(OrderType() == OP_BUY || OrderType() == OP_SELL)
         平掉当前订单("周五强制平仓");
      else
         删除当前挂单("周五删除挂单");
   }
}

bool 删除当前挂单(string 原因)
{
   bool 成功 = OrderDelete(OrderTicket(), clrTomato);
   if(!成功)
   {
      int 错误码 = GetLastError();
      Print(原因, " 失败，票号=", OrderTicket(), " 错误码=", 错误码);
      ResetLastError();
   }
   return(成功);
}

double 当前订单盈利旧点()
{
   if(OrderType() == OP_BUY)
      return((Bid - OrderOpenPrice()) / 旧点());
   if(OrderType() == OP_SELL)
      return((OrderOpenPrice() - Ask) / 旧点());
   return(0.0);
}

double 系统二组合盈利旧点()
{
   double 总手数 = 0.0;
   double 加权开仓 = 0.0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 系统二魔术号 || OrderType() != OP_BUY)
         continue;

      总手数 += OrderLots();
      加权开仓 += OrderOpenPrice() * OrderLots();
   }

   if(总手数 <= 0.0)
      return(0.0);

   double 保本价 = 加权开仓 / 总手数;
   return((Bid - 保本价) / 旧点());
}

//+------------------------------------------------------------------+
//| 统计辅助                                                         |
//+------------------------------------------------------------------+
int 统计魔术号订单(int 魔术号, int 类型, bool 包含挂单)
{
   int 数量 = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 魔术号)
         continue;
      if(类型 >= 0 && OrderType() != 类型)
         continue;
      if(!包含挂单 && OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;
      数量++;
   }
   return(数量);
}

int 统计全部策略订单()
{
   int 数量 = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() == Symbol() && 是策略魔术号(OrderMagicNumber()))
         数量++;
   }
   return(数量);
}

bool 是策略魔术号(int 魔术号)
{
   return(魔术号 == 系统一魔术号 || 魔术号 == 系统二魔术号);
}

double 最近开仓价(int 魔术号, int 类型)
{
   datetime 最近时间 = 0;
   double 价格 = 0.0;

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 魔术号 || OrderType() != 类型)
         continue;

      if(OrderOpenTime() >= 最近时间)
      {
         最近时间 = OrderOpenTime();
         价格 = OrderOpenPrice();
      }
   }

   return(价格);
}

datetime 最近亏损平仓时间()
{
   datetime 最近时间 = 0;

   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() != Symbol() || !是策略魔术号(OrderMagicNumber()))
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;
      if(OrderProfit() + OrderSwap() + OrderCommission() < 0.0 && OrderCloseTime() > 最近时间)
         最近时间 = OrderCloseTime();
   }

   return(最近时间);
}

int 连续亏损次数(int 魔术号)
{
   int 次数 = 0;

   for(int i = OrdersHistoryTotal() - 1; i >= 0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_HISTORY))
         continue;
      if(OrderSymbol() != Symbol() || OrderMagicNumber() != 魔术号)
         continue;
      if(OrderType() != OP_BUY && OrderType() != OP_SELL)
         continue;

      double 结果 = OrderProfit() + OrderSwap() + OrderCommission();
      if(结果 < 0.0)
         次数++;
      else
         break;
   }

   return(次数);
}

//+------------------------------------------------------------------+
//| 信息面板                                                         |
//+------------------------------------------------------------------+
void 绘制信息面板()
{
   double 点差 = (Ask - Bid) / 旧点();
   double ATR值 = iATR(Symbol(), PERIOD_M15, ATR周期, 1) / 旧点();
   double 回撤 = 0.0;
   if(AccountBalance() > 0.0)
      回撤 = (AccountBalance() - AccountEquity()) / AccountBalance() * 100.0;

   string 文本 = "";
   文本 += "金叶子清洁重写版\n";
   文本 += "品种: " + Symbol() + "  周期: " + IntegerToString(Period()) + "\n";
   文本 += "点差旧点: " + DoubleToString(点差, 1) + " / 限制: " + IntegerToString(最大点差旧点) + "\n";
   文本 += "ATR旧点: " + DoubleToString(ATR值, 1) + " / 阈值: " + IntegerToString(ATR最低旧点) + "\n";
   文本 += "GMT偏移: " + IntegerToString(当前GMT偏移()) + "  回撤: " + DoubleToString(回撤, 2) + "%\n";
   文本 += "系统一订单: " + IntegerToString(统计魔术号订单(系统一魔术号, -1, true));
   文本 += "  系统二订单: " + IntegerToString(统计魔术号订单(系统二魔术号, -1, true));

   if(启用新闻过滤 && 处于手动新闻时间())
      文本 += "\n当前处于手动新闻过滤时间";

   Comment(文本);
}
