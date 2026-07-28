// ============================================================================
// Range Trading Stratejisi - Aralık Ticareti
// ============================================================================

#ifndef __RANGE_TRADING_MQH__
#define __RANGE_TRADING_MQH__

#include "BollingerBands.mqh"
#include "MovingAverage.mqh"

// ============================================================================
// RANGE TRADING SINIFI
// ============================================================================

class CRangeTrading
{
private:
   CBollingerBands *bb;       // Bollinger Bands göstergesi
   CMovingAverage *ma;        // Moving Average (orta band)
   string symbol;             // İşlem çifti
   ENUM_TIMEFRAMES tf;        // Timeframe
   int range_period;          // Aralık hesaplama periyodu
   double range_support;      // Alt sınır (Support)
   double range_resistance;   // Üst sınır (Resistance)
   
public:
   // Constructor
   CRangeTrading(string sym, ENUM_TIMEFRAMES timeframe,
                 CBollingerBands *bb_ptr, CMovingAverage *ma_ptr,
                 int period = 20)
   {
      symbol = sym;
      tf = timeframe;
      bb = bb_ptr;
      ma = ma_ptr;
      range_period = period;
      range_support = 0.0;
      range_resistance = 0.0;
      UpdateRangeLevels();
   }
   
   // Destructor
   ~CRangeTrading()
   {
      // Destructors göstergeler tarafından yönetilir
   }
   
   // ========================================================================
   // ARALIK SEVİYELERİ HESAPLAMA
   // ========================================================================
   
   // Aralık seviyelerini güncelle
   void UpdateRangeLevels()
   {
      if(bb == NULL)
         return;
      
      // Bollinger Bands'ı aralık olarak kullan
      range_resistance = bb->GetUpperBand(0);
      range_support = bb->GetLowerBand(0);
   }
   
   // Support seviyesini al
   double GetSupport()
   {
      UpdateRangeLevels();
      return range_support;
   }
   
   // Resistance seviyesini al
   double GetResistance()
   {
      UpdateRangeLevels();
      return range_resistance;
   }
   
   // Aralık genişliğini al
   double GetRangeWidth()
   {
      return GetResistance() - GetSupport();
   }
   
   // ========================================================================
   // ARALIK İÇİNDE KONTROL
   // ========================================================================
   
   // Fiyat aralık içinde mi?
   bool IsPriceInRange(double price)
   {
      double support = GetSupport();
      double resistance = GetResistance();
      
      return (price >= support && price <= resistance);
   }
   
   // Aralık Squeeze var mı? (Çok dar aralık)
   bool IsRangeSqueeze()
   {
      if(bb == NULL)
         return false;
      
      return bb->IsSqueeze();
   }
   
   // ========================================================================
   // SINYAL ÜRETİMİ
   // ========================================================================
   
   // BUY Sinyali (Range Trading)
   // Fiyat alt sınıra yaklaştığında
   int GetBuySignal()
   {
      double price = Close[0];
      double support = GetSupport();
      double range_width = GetRangeWidth();
      
      // Fiyat alt bandın %20 içinde mi?
      double lower_threshold = support + (range_width * 0.20);
      
      if(price < lower_threshold && IsPriceInRange(price))
         return 1;  // BUY sinyali
      
      return 0;  // Sinyal yok
   }
   
   // SELL Sinyali (Range Trading)
   // Fiyat üst sınıra yaklaştığında
   int GetSellSignal()
   {
      double price = Close[0];
      double resistance = GetResistance();
      double range_width = GetRangeWidth();
      
      // Fiyat üst bandın %20 içinde mi?
      double upper_threshold = resistance - (range_width * 0.20);
      
      if(price > upper_threshold && IsPriceInRange(price))
         return -1;  // SELL sinyali
      
      return 0;  // Sinyal yok
   }
   
   // Breakout Sinyali (Range Kırılması)
   // Aralık kırıldığında trend başlayabilir
   int GetBreakoutSignal()
   {
      double price = Close[0];
      double support = GetSupport();
      double resistance = GetResistance();
      
      // Üst breakout
      if(price > resistance)
         return 1;  // LONG breakout
      
      // Alt breakout
      if(price < support)
         return -1;  // SHORT breakout
      
      return 0;  // Breakout yok
   }
   
   // ========================================================================
   // BAND POZİSYON YÜZDESI
   // ========================================================================
   
   // Fiyatın aralık içindeki yüzdesini al
   // 0: Alt banda, 1: Üst banda
   double GetBandwidthPercent()
   {
      double price = Close[0];
      double support = GetSupport();
      double resistance = GetResistance();
      double range_width = GetRangeWidth();
      
      if(range_width == 0)
         return 0.5;
      
      return (price - support) / range_width;
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Strateji aktif mi?
   bool IsValid()
   {
      return (bb != NULL && bb->IsValid() && 
              ma != NULL && ma->IsValid());
   }
   
   // Periyodu güncelle
   void SetRangePeriod(int period)
   {
      range_period = period;
   }
};

#endif // __RANGE_TRADING_MQH__
