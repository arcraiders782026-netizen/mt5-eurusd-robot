//+------------------------------------------------------------------+
//| EURUSD_HybridRobot.mq5                                           |
//| MT5 Hybrid Trading Robot                                         |
//| Strateji: Trend Following + Range Trading + Mean Reversion       |
//| Para Çifti: EURUSD                                               |
//| Timeframe: M15 + M30 (Multi-Timeframe)                           |
//+------------------------------------------------------------------+

#property copyright "arcraiders782026-netizen"
#property link "https://github.com/arcraiders782026-netizen/mt5-eurusd-robot"
#property version "1.0.0"
#property description "Hybrid MT5 Trading Robot for EURUSD"
#property strict

// Include tüm bileşenleri
#include "config/parameters.mqh"
#include "indicators/MovingAverage.mqh"
#include "indicators/RSI.mqh"
#include "indicators/BollingerBands.mqh"
#include "indicators/MACD.mqh"
#include "strategies/TrendFollowing.mqh"
#include "strategies/RangeTrading.mqh"
#include "strategies/MeanReversion.mqh"
#include "strategies/StrategySelector.mqh"
#include "core/Logger.mqh"
#include "core/OrderManager.mqh"
#include "core/RiskManager.mqh"

//============================================================================
// GLOBAL VAR İABLELER
//============================================================================

// Göstergeler (M15)
CMovingAverage *ma_m15;
CRSI *rsi_m15;
CBollingerBands *bb_m15;
CMACD *macd_m15;

// Göstergeler (M30)
CMovingAverage *ma_m30;
CRSI *rsi_m30;
CBollingerBands *bb_m30;
CMACD *macd_m30;

// Stratejiler (M15)
CTrendFollowing *trend_m15;
CRangeTrading *range_m15;
CMeanReversion *mean_reversion_m15;

// Stratejiler (M30)
CTrendFollowing *trend_m30;
CRangeTrading *range_m30;
CMeanReversion *mean_reversion_m30;

// Strateji Selector
CStrategySelector *strategy_selector;

// Yönetim Sistemleri
CLogger *logger;
COrderManager *order_manager;
CRiskManager *risk_manager;

// İş Durumu
bool robot_initialized = false;
int last_signal = 0;
datetime last_order_time = 0;

//============================================================================
// EXPERT ADVISOR BAŞLATMA
//============================================================================

int OnInit()
{
   Print("=== EURUSD Hybrid Robot Başlatılıyor ===");
   
   // Logger oluştur
   logger = new CLogger("EURUSD_HybridRobot.log", LOG_INFO, true, true);
   logger->Info("Robot başlatılıyor...");
   
   // M15 Göstergelerini oluştur
   ma_m15 = new CMovingAverage(SYMBOL, TIMEFRAME_1, MA_Period);
   rsi_m15 = new CRSI(SYMBOL, TIMEFRAME_1, RSI_Period, RSI_Overbought, RSI_Oversold);
   bb_m15 = new CBollingerBands(SYMBOL, TIMEFRAME_1, BB_Period, BB_Deviation);
   macd_m15 = new CMACD(SYMBOL, TIMEFRAME_1, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA);
   
   // M30 Göstergelerini oluştur
   ma_m30 = new CMovingAverage(SYMBOL, TIMEFRAME_2, MA_Period);
   rsi_m30 = new CRSI(SYMBOL, TIMEFRAME_2, RSI_Period, RSI_Overbought, RSI_Oversold);
   bb_m30 = new CBollingerBands(SYMBOL, TIMEFRAME_2, BB_Period, BB_Deviation);
   macd_m30 = new CMACD(SYMBOL, TIMEFRAME_2, MACD_FastEMA, MACD_SlowEMA, MACD_SignalEMA);
   
   // M15 Stratejilerini oluştur
   trend_m15 = new CTrendFollowing(SYMBOL, TIMEFRAME_1, ma_m15, macd_m15, TrendThreshold);
   range_m15 = new CRangeTrading(SYMBOL, TIMEFRAME_1, bb_m15, ma_m15, RangePeriod);
   mean_reversion_m15 = new CMeanReversion(SYMBOL, TIMEFRAME_1, rsi_m15, bb_m15, ma_m15, MRThreshold);
   
   // M30 Stratejilerini oluştur
   trend_m30 = new CTrendFollowing(SYMBOL, TIMEFRAME_2, ma_m30, macd_m30, TrendThreshold);
   range_m30 = new CRangeTrading(SYMBOL, TIMEFRAME_2, bb_m30, ma_m30, RangePeriod);
   mean_reversion_m30 = new CMeanReversion(SYMBOL, TIMEFRAME_2, rsi_m30, bb_m30, ma_m30, MRThreshold);
   
   // Strategy Selector oluştur (M15 kullanarak)
   strategy_selector = new CStrategySelector(trend_m15, range_m15, mean_reversion_m15, logger);
   
   // Order Manager oluştur
   order_manager = new COrderManager(SYMBOL, logger);
   
   // Risk Manager oluştur
   risk_manager = new CRiskManager(SYMBOL, RiskPercent, MinLots, MaxLots, logger);
   
   // Tüm göstergeler geçerli mi kontrol et
   if(!CheckAllIndicators())
   {
      logger->Critical("Göstergeler oluşturulamadı! Robot durduruluyor.");
      return INIT_FAILED;
   }
   
   robot_initialized = true;
   logger->Info("Robot başarıyla başlatıldı!");
   
   Print("=== Robot Başlatıldı ===");
   return INIT_SUCCEEDED;
}

//============================================================================
// EXPERT ADVISOR KAPATMA
//============================================================================

void OnDeinit(const int reason)
{
   logger->Info("Robot kapatılıyor...");
   
   // Tüm açık order'ları kapat (isteğe bağlı)
   // order_manager->CloseAllOrders();
   
   // Bellek temizle
   delete ma_m15;
   delete rsi_m15;
   delete bb_m15;
   delete macd_m15;
   
   delete ma_m30;
   delete rsi_m30;
   delete bb_m30;
   delete macd_m30;
   
   delete trend_m15;
   delete range_m15;
   delete mean_reversion_m15;
   
   delete trend_m30;
   delete range_m30;
   delete mean_reversion_m30;
   
   delete strategy_selector;
   delete order_manager;
   delete risk_manager;
   delete logger;
   
   Print("=== Robot Kapatıldı ===");
}

//============================================================================
// TICKET PROCESSING
//============================================================================

void OnTick()
{
   if(!robot_initialized)
      return;
   
   // Her iki timeframe'de sinyalleri kontrol et
   int signal_m15 = strategy_selector->GetHybridSignal();
   double confidence = strategy_selector->GetSignalConfidence();
   
   // Log sinyali
   if(signal_m15 != 0 && signal_m15 != last_signal)
   {
      logger->Info("Yeni Sinyal: " + (signal_m15 > 0 ? "BUY" : "SELL") + 
                  " (Güven: " + DoubleToString(confidence, 2) + "%)" );
   }
   
   // Order açma mantığı
   if(signal_m15 != 0 && CanOpenOrder())
   {
      double lots = risk_manager->CalculateLotSize(StopLossPips);
      
      if(signal_m15 > 0)  // BUY
      {
         if(order_manager->OpenBuyOrder(lots, StopLossPips, TakeProfitPips))
            last_signal = signal_m15;
      }
      else if(signal_m15 < 0)  // SELL
      {
         if(order_manager->OpenSellOrder(lots, StopLossPips, TakeProfitPips))
            last_signal = signal_m15;
      }
   }
   
   // Her saniye güncelle (Debug)
   if(DebugMode)
   {
      Comment("EURUSD Hybrid Robot\n",
              "Timeframe: M15\n",
              "Sinyal: ", (signal_m15 > 0 ? "BUY" : (signal_m15 < 0 ? "SELL" : "HOLD")), "\n",
              "Güven: ", DoubleToString(confidence, 2), "%\n",
              "Açık Pozisyon: ", order_manager->GetOpenPositionsBySymbol(), "\n",
              "Toplam Kar/Zarar: ", DoubleToString(risk_manager->GetTotalProfit(), 2));
   }
}

//============================================================================
// YARDıMCı FONKSİYONLAR
//============================================================================

// Tüm göstergeler geçerli mi?
bool CheckAllIndicators()
{
   bool all_valid = true;
   
   if(!ma_m15->IsValid() || !ma_m30->IsValid())
   {
      logger->Error("Moving Average göstergesi geçersiz!");
      all_valid = false;
   }
   
   if(!rsi_m15->IsValid() || !rsi_m30->IsValid())
   {
      logger->Error("RSI göstergesi geçersiz!");
      all_valid = false;
   }
   
   if(!bb_m15->IsValid() || !bb_m30->IsValid())
   {
      logger->Error("Bollinger Bands göstergesi geçersiz!");
      all_valid = false;
   }
   
   if(!macd_m15->IsValid() || !macd_m30->IsValid())
   {
      logger->Error("MACD göstergesi geçersiz!");
      all_valid = false;
   }
   
   return all_valid;
}

// Order açılabilir mi?
bool CanOpenOrder()
{
   // Maksimum pozisyon kontrolü
   if(!risk_manager->CanOpenPosition(MaxOpenPositions))
      return false;
   
   // Son order'dan sonra en az belirli kadar zaman geçmesi
   if(TimeCurrent() - last_order_time < 60)  // En az 60 saniye
      return false;
   
   // Trading saatleri kontrolü (isteğe bağlı)
   if(UseTradingHours)
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      if(dt.hour < StartHour || dt.hour >= EndHour)
         return false;
   }
   
   return true;
}

//+------------------------------------------------------------------+
// END OF EXPERT ADVISOR
//+------------------------------------------------------------------+
