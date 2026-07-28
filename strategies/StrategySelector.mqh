// ============================================================================
// Strategy Selector - Strateji Seçim Motoru
// ============================================================================

#ifndef __STRATEGY_SELECTOR_MQH__
#define __STRATEGY_SELECTOR_MQH__

#include "TrendFollowing.mqh"
#include "RangeTrading.mqh"
#include "MeanReversion.mqh"
#include "Logger.mqh"

// ============================================================================
// STRATEJI TÜRÜ ENUM
// ============================================================================

enum ENUM_STRATEGY_TYPE
{
   STRATEGY_TREND = 1,        // Trend takibi
   STRATEGY_RANGE = 2,        // Aralık ticareti
   STRATEGY_MEAN_REVERSION = 3, // Ortalamaya dönüş
   STRATEGY_HYBRID = 4        // Hybrid (Tümü)
};

// ============================================================================
// STRATEJI SELECTOR SINIFI
// ============================================================================

class CStrategySelector
{
private:
   CTrendFollowing *trend_strategy;
   CRangeTrading *range_strategy;
   CMeanReversion *mean_reversion_strategy;
   
   ENUM_STRATEGY_TYPE active_strategy;
   CLogger *logger;
   
public:
   // Constructor
   CStrategySelector(CTrendFollowing *trend_ptr,
                    CRangeTrading *range_ptr,
                    CMeanReversion *mr_ptr,
                    CLogger *log_ptr)
   {
      trend_strategy = trend_ptr;
      range_strategy = range_ptr;
      mean_reversion_strategy = mr_ptr;
      logger = log_ptr;
      active_strategy = STRATEGY_HYBRID;  // Varsayılan: Hybrid
   }
   
   // Destructor
   ~CStrategySelector()
   {
      // Stratejiler dışarıdan yönetilir
   }
   
   // ========================================================================
   // STRATEJİ SEÇİMİ
   // ========================================================================
   
   // Aktif stratejiyi ayarla
   void SetActiveStrategy(ENUM_STRATEGY_TYPE strategy)
   {
      active_strategy = strategy;
      
      if(logger != NULL)
      {
         string strategy_name = "";
         
         switch(strategy)
         {
            case STRATEGY_TREND:
               strategy_name = "Trend Following";
               break;
            case STRATEGY_RANGE:
               strategy_name = "Range Trading";
               break;
            case STRATEGY_MEAN_REVERSION:
               strategy_name = "Mean Reversion";
               break;
            case STRATEGY_HYBRID:
               strategy_name = "Hybrid (Tümü)";
               break;
         }
         
         logger->Info("Aktif Strateji Değiştirildi: " + strategy_name);
      }
   }
   
   // Aktif stratejiyi al
   ENUM_STRATEGY_TYPE GetActiveStrategy()
   {
      return active_strategy;
   }
   
   // ========================================================================
   // SINYAL ÜRETİMİ
   // ========================================================================
   
   // Unified sinyal üret (-1: SELL, 0: HOLD, 1: BUY)
   int GetSignal()
   {
      switch(active_strategy)
      {
         case STRATEGY_TREND:
            return GetTrendSignal();
         
         case STRATEGY_RANGE:
            return GetRangeSignal();
         
         case STRATEGY_MEAN_REVERSION:
            return GetMeanReversionSignal();
         
         case STRATEGY_HYBRID:
            return GetHybridSignal();
         
         default:
            return 0;  // HOLD
      }
   }
   
   // ========================================================================
   // BİREYSEL STRATEJİ SİNYALLERİ
   // ========================================================================
   
   // Trend Follow sinyali
   int GetTrendSignal()
   {
      if(trend_strategy == NULL || !trend_strategy->IsValid())
         return 0;
      
      int buy_signal = trend_strategy->GetBuySignal();
      int sell_signal = trend_strategy->GetSellSignal();
      
      if(buy_signal > 0)
         return 1;
      else if(sell_signal < 0)
         return -1;
      
      return 0;
   }
   
   // Range Trading sinyali
   int GetRangeSignal()
   {
      if(range_strategy == NULL || !range_strategy->IsValid())
         return 0;
      
      int buy_signal = range_strategy->GetBuySignal();
      int sell_signal = range_strategy->GetSellSignal();
      
      if(buy_signal > 0)
         return 1;
      else if(sell_signal < 0)
         return -1;
      
      return 0;
   }
   
   // Mean Reversion sinyali
   int GetMeanReversionSignal()
   {
      if(mean_reversion_strategy == NULL || !mean_reversion_strategy->IsValid())
         return 0;
      
      int buy_signal = mean_reversion_strategy->GetBuySignal();
      int sell_signal = mean_reversion_strategy->GetSellSignal();
      
      if(buy_signal > 0)
         return 1;
      else if(sell_signal < 0)
         return -1;
      
      return 0;
   }
   
   // ========================================================================
   // HYBRID SİNYAL (Tüm stratejiler birleştirilir)
   // ========================================================================
   
   // Hybrid sinyal: Çoğunluk oyu sistemi
   int GetHybridSignal()
   {
      int buy_votes = 0;
      int sell_votes = 0;
      int hold_votes = 0;
      
      // Trend Following oyusu
      int trend_signal = GetTrendSignal();
      if(trend_signal > 0) buy_votes++;
      else if(trend_signal < 0) sell_votes++;
      else hold_votes++;
      
      // Range Trading oyusu
      int range_signal = GetRangeSignal();
      if(range_signal > 0) buy_votes++;
      else if(range_signal < 0) sell_votes++;
      else hold_votes++;
      
      // Mean Reversion oyusu
      int mr_signal = GetMeanReversionSignal();
      if(mr_signal > 0) buy_votes++;
      else if(mr_signal < 0) sell_votes++;
      else hold_votes++;
      
      if(logger != NULL)
      {
         logger->Debug("Hybrid Voting - BUY: " + IntegerToString(buy_votes) + 
                      " SELL: " + IntegerToString(sell_votes) + 
                      " HOLD: " + IntegerToString(hold_votes));
      }
      
      // Çoğunluk oyu
      if(buy_votes > sell_votes && buy_votes > 1)
         return 1;  // BUY
      else if(sell_votes > buy_votes && sell_votes > 1)
         return -1;  // SELL
      
      return 0;  // HOLD
   }
   
   // ========================================================================
   // STRATEJİ GÜVEN SEVİYESİ
   // ========================================================================
   
   // Sinyalin güven yüzdesini al (0-100)
   double GetSignalConfidence()
   {
      int buy_votes = 0;
      int sell_votes = 0;
      
      // Trend Following
      int trend_signal = GetTrendSignal();
      if(trend_signal > 0) buy_votes++;
      else if(trend_signal < 0) sell_votes++;
      
      // Range Trading
      int range_signal = GetRangeSignal();
      if(range_signal > 0) buy_votes++;
      else if(range_signal < 0) sell_votes++;
      
      // Mean Reversion
      int mr_signal = GetMeanReversionSignal();
      if(mr_signal > 0) buy_votes++;
      else if(mr_signal < 0) sell_votes++;
      
      // Toplam oylayan (maksimum 3)
      int total_votes = buy_votes + sell_votes;
      
      if(total_votes == 0)
         return 0.0;
      
      // Çoğunluğun yüzdesi
      int majority = (buy_votes > sell_votes) ? buy_votes : sell_votes;
      return (double)majority / 3.0 * 100.0;  // 0-100
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Tüm stratejiler geçerli mi?
   bool AllStrategiesValid()
   {
      return (trend_strategy != NULL && trend_strategy->IsValid() &&
              range_strategy != NULL && range_strategy->IsValid() &&
              mean_reversion_strategy != NULL && mean_reversion_strategy->IsValid());
   }
};

#endif // __STRATEGY_SELECTOR_MQH__
