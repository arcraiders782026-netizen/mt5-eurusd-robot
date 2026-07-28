// ============================================================================
// MACD (Moving Average Convergence Divergence) - Momentum ve Trend Göstergesi
// ============================================================================

#ifndef __MACD_MQH__
#define __MACD_MQH__

// ============================================================================
// MACD SINIFI
// ============================================================================

class CMACD
{
private:
   int handle;           // MACD handle
   int fast_ema;         // Hızlı EMA (varsayılan: 12)
   int slow_ema;         // Yavaş EMA (varsayılan: 26)
   int signal_ema;       // Signal EMA (varsayılan: 9)
   string symbol;        // İşlem çifti
   ENUM_TIMEFRAMES tf;   // Timeframe
   
public:
   // Constructor
   CMACD(string sym, ENUM_TIMEFRAMES timeframe, 
         int fast = 12, int slow = 26, int signal = 9)
   {
      symbol = sym;
      tf = timeframe;
      fast_ema = fast;
      slow_ema = slow;
      signal_ema = signal;
      handle = INVALID_HANDLE;
      CreateIndicator();
   }
   
   // Destructor
   ~CMACD()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
   
   // ========================================================================
   // İNDİKATÖR OLUŞTURMA
   // ========================================================================
   
   bool CreateIndicator()
   {
      handle = iMACD(symbol, tf, fast_ema, slow_ema, signal_ema, PRICE_CLOSE);
      
      if(handle == INVALID_HANDLE)
      {
         Print("HATA: MACD göstergesi oluşturulamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // GETTER FONKSİYONLAR
   // ========================================================================
   
   // MACD Hattı (Main Line)
   double GetMACD(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
      {
         Print("HATA: MACD değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Signal Hattı
   double GetSignal(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 1, shift, 1, buffer) <= 0)
      {
         Print("HATA: Signal değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Histogram (MACD - Signal)
   double GetHistogram(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 2, shift, 1, buffer) <= 0)
      {
         Print("HATA: Histogram değeri alınamadı!");
         return 0.0;
      }
      
      return buffer[0];
   }
   
   // Tüm değerleri bir kez al (daha verimli)
   bool GetAllValues(int shift, double &macd, double &signal, double &histogram)
   {
      double buf_macd[], buf_signal[], buf_histogram[];
      
      if(CopyBuffer(handle, 0, shift, 1, buf_macd) <= 0)
         return false;
      if(CopyBuffer(handle, 1, shift, 1, buf_signal) <= 0)
         return false;
      if(CopyBuffer(handle, 2, shift, 1, buf_histogram) <= 0)
         return false;
      
      macd = buf_macd[0];
      signal = buf_signal[0];
      histogram = buf_histogram[0];
      
      return true;
   }
   
   // ========================================================================
   // SINYAL TESPITI
   // ========================================================================
   
   // Bullish Crossover (MACD Signal'ı kesip üstüne geçti)
   bool IsBullishCrossover()
   {
      double macd_current = GetMACD(0);
      double signal_current = GetSignal(0);
      
      double macd_previous = GetMACD(1);
      double signal_previous = GetSignal(1);
      
      // Önceki: MACD <= Signal
      // Şimdiki: MACD > Signal
      return (macd_previous <= signal_previous && macd_current > signal_current);
   }
   
   // Bearish Crossover (MACD Signal'ın altına geçti)
   bool IsBearishCrossover()
   {
      double macd_current = GetMACD(0);
      double signal_current = GetSignal(0);
      
      double macd_previous = GetMACD(1);
      double signal_previous = GetSignal(1);
      
      // Önceki: MACD >= Signal
      // Şimdiki: MACD < Signal
      return (macd_previous >= signal_previous && macd_current < signal_current);
   }
   
   // ========================================================================
   // MOMENTUM TESPITI
   // ========================================================================
   
   // MACD pozitif mi? (Yükseliş momentum'u)
   bool IsPositive()
   {
      return GetMACD(0) > 0.0;
   }
   
   // MACD negatif mi? (Düşüş momentum'u)
   bool IsNegative()
   {
      return GetMACD(0) < 0.0;
   }
   
   // Histogram pozitif mi?
   bool IsHistogramPositive()
   {
      return GetHistogram(0) > 0.0;
   }
   
   // Histogram negatif mi?
   bool IsHistogramNegative()
   {
      return GetHistogram(0) < 0.0;
   }
   
   // ========================================================================
   // TREND GÜÇÜ TESPITI
   // ========================================================================
   
   // Uptrend güçlü mü?
   bool IsStrongUptrend()
   {
      double macd = GetMACD(0);
      double signal = GetSignal(0);
      double histogram = GetHistogram(0);
      
      return (macd > signal && macd > 0.0 && histogram > 0.0);
   }
   
   // Downtrend güçlü mü?
   bool IsStrongDowntrend()
   {
      double macd = GetMACD(0);
      double signal = GetSignal(0);
      double histogram = GetHistogram(0);
      
      return (macd < signal && macd < 0.0 && histogram < 0.0);
   }
   
   // ========================================================================
   // DIVERGENCE TESPITI
   // ========================================================================
   
   // Bullish Divergence (Fiyat düşüyor ama MACD yükseliyor)
   bool IsBullishDivergence()
   {
      double macd_current = GetMACD(0);
      double macd_previous = GetMACD(1);
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      return (price_current < price_previous && macd_current > macd_previous);
   }
   
   // Bearish Divergence (Fiyat yükseliyor ama MACD düşüyor)
   bool IsBearishDivergence()
   {
      double macd_current = GetMACD(0);
      double macd_previous = GetMACD(1);
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      return (price_current > price_previous && macd_current < macd_previous);
   }
   
   // ========================================================================
   // ZERO LINE TESPITI
   // ========================================================================
   
   // MACD Zero Line üstünde mi?
   bool IsAboveZeroLine()
   {
      return GetMACD(0) > 0.0;
   }
   
   // MACD Zero Line altında mı?
   bool IsBelowZeroLine()
   {
      return GetMACD(0) < 0.0;
   }
   
   // MACD Zero Line kesişimi (Bullish)
   bool IsBullishZeroCrossover()
   {
      double macd_current = GetMACD(0);
      double macd_previous = GetMACD(1);
      
      return (macd_previous <= 0.0 && macd_current > 0.0);
   }
   
   // MACD Zero Line kesişimi (Bearish)
   bool IsBearishZeroCrossover()
   {
      double macd_current = GetMACD(0);
      double macd_previous = GetMACD(1);
      
      return (macd_previous >= 0.0 && macd_current < 0.0);
   }
   
   // ========================================================================
   // YARDıMCı FONKSİYONLAR
   // ========================================================================
   
   // Handle geçerli mi?
   bool IsValid()
   {
      return handle != INVALID_HANDLE;
   }
   
   // Parametreleri al
   int GetFastEMA() { return fast_ema; }
   int GetSlowEMA() { return slow_ema; }
   int GetSignalEMA() { return signal_ema; }
};

#endif // __MACD_MQH__