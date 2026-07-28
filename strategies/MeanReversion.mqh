// ============================================================================
// Mean Reversion Stratejisi - Ortalamaya Dönüş
// ============================================================================

#ifndef __MEAN_REVERSION_MQH__
#define __MEAN_REVERSION_MQH__

#include "RSI.mqh"
#include "BollingerBands.mqh"
#include "MovingAverage.mqh"

// ============================================================================
// MEAN REVERSION SINIFI
// ============================================================================

class CMeanReversion
{
private:
   CRSI *rsi;                 // RSI göstergesi
   CBollingerBands *bb;       // Bollinger Bands göstergesi
   CMovingAverage *ma;        // Moving Average (orta band)
   string symbol;             // İşlem çifti
   ENUM_TIMEFRAMES tf;        // Timeframe
   double mr_threshold;       // Ortalamaya dönüş eşiği
   
public:
   // Constructor
   CMeanReversion(string sym, ENUM_TIMEFRAMES timeframe,
                  CRSI *rsi_ptr, CBollingerBands *bb_ptr,
                  CMovingAverage *ma_ptr,
                  double threshold = 2.0)
   {
      symbol = sym;
      tf = timeframe;
      rsi = rsi_ptr;
      bb = bb_ptr;
      ma = ma_ptr;
      mr_threshold = threshold;
   }
   
   // Destructor
   ~CMeanReversion()
   {
      // Destructors göstergeler tarafından yönetilir
   }
   
   // ========================================================================
   // AŞIRI İŞLEM TESPITI
   // ========================================================================
   
   // Aşırı satış (Oversold) - Fiyat çok düştü
   bool IsOversoldCondition()
   {
      if(rsi == NULL)
         return false;
      
      // RSI < 30 (Oversold)
      bool rsi_condition = rsi->IsOversold();
      
      // Fiyat alt banda yakın
      double price = Close[0];
      bool bb_condition = false;
      
      if(bb != NULL)
         bb_condition = bb->IsNearLowerBand(price, 0.80);
      
      return rsi_condition || bb_condition;
   }
   
   // Aşırı alış (Overbought) - Fiyat çok yükseldi
   bool IsOverboughtCondition()
   {
      if(rsi == NULL)
         return false;
      
      // RSI > 70 (Overbought)
      bool rsi_condition = rsi->IsOverbought();
      
      // Fiyat üst banda yakın
      double price = Close[0];
      bool bb_condition = false;
      
      if(bb != NULL)
         bb_condition = bb->IsNearUpperBand(price, 0.80);
      
      return rsi_condition || bb_condition;
   }
   
   // ========================================================================
   // ORTALAMAYA DÖNÜŞ TESPITI
   // ========================================================================
   
   // Fiyat ortalamadan ne kadar uzak?
   double GetDistanceFromMA()
   {
      if(ma == NULL)
         return 0.0;
      
      double price = Close[0];
      double ma_value = ma->GetValue(0);
      
      double distance = price - ma_value;
      return distance;
   }
   
   // Fiyat ortalamadan uzak mı?
   bool IsFarFromMA(double std_dev = 2.0)
   {
      if(bb == NULL)
         return false;
      
      double price = Close[0];
      double middle = bb->GetMiddleBand(0);
      
      // Bollinger Bands kullanarak standart sapma hesapla
      double upper = bb->GetUpperBand(0);
      double bandwidth = (upper - middle) / 2.0;
      
      double distance = MathAbs(price - middle);
      
      return distance > (bandwidth * std_dev);
   }
   
   // ========================================================================
   // SINYAL ÜRETİMİ
   // ========================================================================
   
   // BUY Sinyali (Mean Reversion)
   // Fiyat çok satıldığında, ortalamaya dönecek
   int GetBuySignal()
   {
      // Oversold koşulu
      if(!IsOversoldCondition())
         return 0;
      
      // Divergence kontrolü (Fiyat düşüyor ama RSI yükseliyor)
      if(rsi != NULL && rsi->IsBullishDivergence())
         return 1;  // Güçlü BUY sinyali
      
      // Ortalama dönüş
      if(GetDistanceFromMA() < -mr_threshold * 0.01)
         return 1;  // BUY sinyali
      
      return 0;  // Sinyal yok
   }
   
   // SELL Sinyali (Mean Reversion)
   // Fiyat çok alındığında, ortalamaya dönecek
   int GetSellSignal()
   {
      // Overbought koşulu
      if(!IsOverboughtCondition())
         return 0;
      
      // Divergence kontrolü (Fiyat yükseliyor ama RSI düşüyor)
      if(rsi != NULL && rsi->IsBearishDivergence())
         return -1;  // Güçlü SELL sinyali
      
      // Ortalama dönüş
      if(GetDistanceFromMA() > mr_threshold * 0.01)
         return -1;  // SELL sinyali
      
      return 0;  // Sinyal yok
   }
   
   // ========================================================================
   // RSI LEVEL TESPITI
   // ========================================================================
   
   // RSI değerini al
   double GetRSI()
   {
      if(rsi == NULL)
         return 50.0;
      
      return rsi->GetValue(0);
   }
   
   // RSI aşırı işlem durumu
   int GetRSIExtreme()
   {
      if(rsi == NULL)
         return 0;
      
      return rsi->GetExtremeCondition();
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Eşiği güncelle
   void SetMRThreshold(double threshold)
   {
      mr_threshold = threshold;
   }
   
   // Strateji aktif mi?
   bool IsValid()
   {
      return (rsi != NULL && rsi->IsValid() &&
              bb != NULL && bb->IsValid() &&
              ma != NULL && ma->IsValid());
   }
};

#endif // __MEAN_REVERSION_MQH__
