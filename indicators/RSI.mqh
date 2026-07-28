// ============================================================================
// RSI (Relative Strength Index) - Aşırı İşlem Tespit Göstergesi
// ============================================================================

#ifndef __RSI_MQH__
#define __RSI_MQH__

// ============================================================================
// RSI SINIFI
// ============================================================================

class CRSI
{
private:
   int handle;           // RSI handle
   int period;           // RSI periyodu
   double overbought;    // Çok alındı seviyesi (varsayılan: 70)
   double oversold;      // Çok satıldı seviyesi (varsayılan: 30)
   string symbol;        // İşlem çifti
   ENUM_TIMEFRAMES tf;   // Timeframe
   
public:
   // Constructor
   CRSI(string sym, ENUM_TIMEFRAMES timeframe, int per, 
        double ob = 70.0, double os = 30.0)
   {
      symbol = sym;
      tf = timeframe;
      period = per;
      overbought = ob;
      oversold = os;
      handle = INVALID_HANDLE;
      CreateIndicator();
   }
   
   // Destructor
   ~CRSI()
   {
      if(handle != INVALID_HANDLE)
         IndicatorRelease(handle);
   }
   
   // ========================================================================
   // İNDİKATÖR OLUŞTURMA
   // ========================================================================
   
   bool CreateIndicator()
   {
      handle = iRSI(symbol, tf, period, PRICE_CLOSE);
      
      if(handle == INVALID_HANDLE)
      {
         Print("HATA: RSI göstergesi oluşturulamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // GETTER FONKSİYONLAR
   // ========================================================================
   
   // Son RSI değerini al (0-100)
   double GetValue(int shift = 0)
   {
      double buffer[];
      
      if(CopyBuffer(handle, 0, shift, 1, buffer) <= 0)
      {
         Print("HATA: RSI değeri alınamadı!");
         return 50.0;  // Orta değer
      }
      
      return buffer[0];
   }
   
   // Birden fazla RSI değerini al
   bool GetValues(int count, double &values[])
   {
      if(CopyBuffer(handle, 0, 0, count, values) <= 0)
      {
         Print("HATA: RSI değerleri alınamadı!");
         return false;
      }
      
      return true;
   }
   
   // ========================================================================
   // AŞIRI İŞLEM TESPITI
   // ========================================================================
   
   // Çok alındı mı? (Overbought)
   bool IsOverbought()
   {
      double rsi = GetValue(0);
      return rsi > overbought;
   }
   
   // Çok satıldı mı? (Oversold)
   bool IsOversold()
   {
      double rsi = GetValue(0);
      return rsi < oversold;
   }
   
   // Aşırı işlem durumu al (-1: Oversold, 0: Normal, 1: Overbought)
   int GetExtremeCondition()
   {
      double rsi = GetValue(0);
      
      if(rsi > overbought)
         return 1;      // Çok alındı
      else if(rsi < oversold)
         return -1;     // Çok satıldı
      else
         return 0;      // Normal
   }
   
   // ========================================================================
   // DIVERGENCE TESPITI
   // ========================================================================
   
   // Bullish Divergence (Yükseliş Sapması)
   // Fiyat düşüyor ama RSI yükseliyor
   bool IsBullishDivergence()
   {
      double rsi_current = GetValue(0);
      double rsi_previous = GetValue(1);
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      return (price_current < price_previous && rsi_current > rsi_previous);
   }
   
   // Bearish Divergence (Düşüş Sapması)
   // Fiyat yükseliyor ama RSI düşüyor
   bool IsBearishDivergence()
   {
      double rsi_current = GetValue(0);
      double rsi_previous = GetValue(1);
      
      double price_current = Close[0];
      double price_previous = Close[1];
      
      return (price_current > price_previous && rsi_current < rsi_previous);
   }
   
   // ========================================================================
   // RSI SEVİYE KONTROLLERI
   // ========================================================================
   
   // RSI belirli seviyenin üstünde mi?
   bool IsAboveLevel(double level)
   {
      return GetValue(0) > level;
   }
   
   // RSI belirli seviyenin altında mı?
   bool IsBelowLevel(double level)
   {
      return GetValue(0) < level;
   }
   
   // RSI orta çizginin (50) üstünde mi?
   bool IsAboveMiddle()
   {
      return GetValue(0) > 50.0;
   }
   
   // RSI orta çizginin (50) altında mı?
   bool IsBelowMiddle()
   {
      return GetValue(0) < 50.0;
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
   
   // Overbought seviyesini al
   double GetOverboughtLevel()
   {
      return overbought;
   }
   
   // Oversold seviyesini al
   double GetOversoldLevel()
   {
      return oversold;
   }
   
   // Seviyeyi değiştir
   void SetLevels(double ob, double os)
   {
      overbought = ob;
      oversold = os;
   }
};

#endif // __RSI_MQH__