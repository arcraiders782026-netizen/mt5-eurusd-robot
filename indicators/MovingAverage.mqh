// ============================================================================
// Moving Average (MA) - Trend Tespit Göstergesi
// ============================================================================

#ifndef __MOVING_AVERAGE_MQH__
#define __MOVING_AVERAGE_MQH__

// ============================================================================
// MOVING AVERAGE SINIFI
// ============================================================================

class CMovingAverage
{
private:
   int handle;           // MA handle
   int period;           // MA periyodu
   string symbol;        // İşlem çifti
   ENUM_TIMEFRAMES tf;   // Timeframe
   
public:
   // Constructor
   CMovingAverage(string sym, ENUM_TIMEFRAMES timeframe, int per)
   {
      symbol = sym;
      tf = timeframe;
      period = per;
      handle = INVALID_HANDLE;
      CreateIndicator();
   }
   
   // Destructor
   ~CMovingAverage()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
   
   // ========================================================================
   // İNDİKATÖR OLUŞTURMA
   // ========================================================================
   
   bool CreateIndicator()
   {
      handle = iMA(symbol, tf, period, 0, MODE_SMA, PRICE_CLOSE);
      
      if(handle == INVALID_HANDLE)
      {
         Print("HATA: MA göstergesi oluşturulamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // GETTER FONKSİYONLAR
   // ========================================================================
   
   // Son MA değerini al
   double GetValue(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
      {
         Print("HATA: MA değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Birden fazla MA değerini al
   bool GetValues(int count, double &values[])
   {
      if(CopyBuffer(handle, 0, 0, count, values) <= 0)
      {
         Print("HATA: MA değerleri alınamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // TREND TESPITI
   // ========================================================================
   
   // Uptrend mi? (Fiyat > MA)
   bool IsUptrend(double price)
   {
      double ma = GetValue(0);
      return price > ma;
   }
   
   // Downtrend mi? (Fiyat < MA)
   bool IsDowntrend(double price)
   {
      double ma = GetValue(0);
      return price < ma;
   }
   
   // Trend yönü al (-1: Down, 0: Yok, 1: Up)
   int GetTrendDirection(double price)
   {
      double ma = GetValue(0);
      
      if(price > ma * 1.0005)      // %0.05 fark
         return 1;                  // Uptrend
      else if(price < ma * 0.9995)  // -%0.05 fark
         return -1;                 // Downtrend
      else
         return 0;                  // Trend yok
   }
   
   // ========================================================================
   // MA İŞLEMLERİ
   // ========================================================================
   
   // MA kesişimi kontrol et (Bullish)
   bool IsBullishCrossover()
   {
      double ma_current = GetValue(0);   // Şimdiki MA
      double ma_previous = GetValue(1);  // Önceki MA
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      // Fiyat altından üzerine geçti
      return (price_previous <= ma_previous && price_current > ma_current);
   }
   
   // MA kesişimi kontrol et (Bearish)
   bool IsBearishCrossover()
   {
      double ma_current = GetValue(0);
      double ma_previous = GetValue(1);
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      // Fiyat üstünden altına geçti
      return (price_previous >= ma_previous && price_current < ma_current);
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Handle geçerli mi?
   bool IsValid()
   {
      return handle != INVALID_HANDLE;
   }
   
   // Periyodu al
   int GetPeriod()
   {
      return period;
   }
};

#endif // __MOVING_AVERAGE_MQH__