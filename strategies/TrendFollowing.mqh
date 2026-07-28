// ============================================================================
// Trend Following Stratejisi - Trend Takibi
// ============================================================================

#ifndef __TREND_FOLLOWING_MQH__
#define __TREND_FOLLOWING_MQH__

#include "MovingAverage.mqh"
#include "MACD.mqh"

// ============================================================================
// TREND FOLLOWING SINIFI
// ============================================================================

class CTrendFollowing
{
private:
   CMovingAverage *ma;        // Moving Average göstergesi
   CMACD *macd;               // MACD göstergesi
   string symbol;             // İşlem çifti
   ENUM_TIMEFRAMES tf;        // Timeframe
   double trend_threshold;    // Trend eşiği
   
public:
   // Constructor
   CTrendFollowing(string sym, ENUM_TIMEFRAMES timeframe, 
                   CMovingAverage *ma_ptr, CMACD *macd_ptr,
                   double threshold = 0.0015)
   {
      symbol = sym;
      tf = timeframe;
      ma = ma_ptr;
      macd = macd_ptr;
      trend_threshold = threshold;
   }
   
   // Destructor
   ~CTrendFollowing()
   {
      // Destructors göstergiler tarafından yönetilir
   }
   
   // ========================================================================
   // TREND TESPIT FONKSİYONLARI
   // ========================================================================
   
   // Güçlü Uptrend var mı?
   bool IsStrongUptrend()
   {
      if(ma == NULL || macd == NULL)
         return false;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      
      // MA şartı: Fiyat > MA
      bool ma_condition = price > ma_value * (1 + trend_threshold);
      
      // MACD şartı: Güçlü yükseliş momentum
      bool macd_condition = macd->IsStrongUptrend();
      
      return ma_condition && macd_condition;
   }
   
   // Güçlü Downtrend var mı?
   bool IsStrongDowntrend()
   {
      if(ma == NULL || macd == NULL)
         return false;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      
      // MA şartı: Fiyat < MA
      bool ma_condition = price < ma_value * (1 - trend_threshold);
      
      // MACD şartı: Güçlü düşüş momentum
      bool macd_condition = macd->IsStrongDowntrend();
      
      return ma_condition && macd_condition;
   }
   
   // Uptrend trend devam ediyor mu?
   bool IsTrendingUp()
   {
      if(ma == NULL)
         return false;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      
      return price > ma_value;
   }
   
   // Downtrend trend devam ediyor mu?
   bool IsTrendingDown()
   {
      if(ma == NULL)
         return false;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      
      return price < ma_value;
   }
   
   // ========================================================================
   // SINYAL ÜRETİMİ
   // ========================================================================
   
   // BUY Sinyali (Trend Takibi)
   // MA Crossover + MACD onayı
   int GetBuySignal()
   {
      if(ma == NULL || macd == NULL)
         return 0;
      
      // Bullish MA Crossover
      if(ma->IsBullishCrossover())
      {
         // MACD Bullish onayı
         if(macd->IsBullishCrossover() || macd->IsAboveZeroLine())
            return 1;  // BUY sinyali
      }
      
      // Trend devam et (Güçlü uptrend)
      if(IsStrongUptrend())
         return 1;  // BUY sinyali
      
      return 0;  // Sinyal yok
   }
   
   // SELL Sinyali (Trend Takibi)
   // MA Crossover + MACD onayı
   int GetSellSignal()
   {
      if(ma == NULL || macd == NULL)
         return 0;
      
      // Bearish MA Crossover
      if(ma->IsBearishCrossover())
      {
         // MACD Bearish onayı
         if(macd->IsBearishCrossover() || macd->IsBelowZeroLine())
            return -1;  // SELL sinyali
      }
      
      // Trend devam et (Güçlü downtrend)
      if(IsStrongDowntrend())
         return -1;  // SELL sinyali
      
      return 0;  // Sinyal yok
   }
   
   // ========================================================================
   // TREND GÜCÜ ÖLÇÜMÜ
   // ========================================================================
   
   // Trend gücü yüzdesini al (0-100)
   double GetTrendStrength()
   {
      if(ma == NULL)
         return 0.0;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      double difference = price - ma_value;
      
      // Yüzdesi hesapla
      double strength = (difference / ma_value) * 100.0;
      
      return MathAbs(strength);
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Eşiği güncelle
   void SetTrendThreshold(double threshold)
   {
      trend_threshold = threshold;
   }
   
   // Strateji aktif mi?
   bool IsValid()
   {
      return (ma != NULL && ma->IsValid() && 
              macd != NULL && macd->IsValid());
   }
};

#endif // __TREND_FOLLOWING_MQH__
