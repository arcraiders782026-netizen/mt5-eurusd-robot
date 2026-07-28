// ============================================================================
// Logger - Hata Ayıklama ve Log Sistemi
// ============================================================================

#ifndef __LOGGER_MQH__
#define __LOGGER_MQH__

#include <stdlib.mqh>

// ============================================================================
// LOG SEVİYELERİ
// ============================================================================

enum ENUM_LOG_LEVEL
{
   LOG_DEBUG = 0,     // Debug bilgileri
   LOG_INFO = 1,      // Normal bilgiler
   LOG_WARNING = 2,   // Uyarılar
   LOG_ERROR = 3,     // Hatalar
   LOG_CRITICAL = 4   // Kritik hatalar
};

// ============================================================================
// LOGGER SINIFI
// ============================================================================

class CLogger
{
private:
   string log_filename;       // Log dosyası adı
   ENUM_LOG_LEVEL log_level;  // Minimum log seviyesi
   bool file_logging;         // Dosyaya kayıt aktif mi?
   bool console_logging;      // Console'ye yazdırma aktif mi?
   int log_file_handle;       // File handle
   
public:
   // Constructor
   CLogger(string filename = "robot_log.txt", 
           ENUM_LOG_LEVEL level = LOG_INFO,
           bool use_file = true,
           bool use_console = true)
   {
      log_filename = filename;
      log_level = level;
      file_logging = use_file;
      console_logging = use_console;
      log_file_handle = INVALID_HANDLE;
      
      if(file_logging)
         OpenLogFile();
   }
   
   // Destructor
   ~CLogger()
   {
      if(log_file_handle != INVALID_HANDLE)
         FileClose(log_file_handle);
   }
   
   // ========================================================================
   // LOG DOSYASI YÖNETIMI
   // ========================================================================
   
   bool OpenLogFile()
   {
      log_file_handle = FileOpen(log_filename, 
                                 FILE_READ | FILE_WRITE | FILE_TXT,
                                 "\n");
      
      if(log_file_handle == INVALID_HANDLE)
      {
         Print("HATA: Log dosyası açılamadı!");
         return false;
      }
      
      FileSeek(log_file_handle, 0, SEEK_END);  // Dosyanın sonuna git
      return true;
   }
   
   void CloseLogFile()
   {
      if(log_file_handle != INVALID_HANDLE)
      {
         FileClose(log_file_handle);
         log_file_handle = INVALID_HANDLE;
      }
   }
   
   // ========================================================================
   // LOG YAZMA FONKSİYONLARI
   // ========================================================================
   
   // Debug log
   void Debug(string message)
   {
      if(log_level <= LOG_DEBUG)
         WriteLog("[DEBUG]", message);
   }
   
   // Info log
   void Info(string message)
   {
      if(log_level <= LOG_INFO)
         WriteLog("[INFO]", message);
   }
   
   // Warning log
   void Warning(string message)
   {
      if(log_level <= LOG_WARNING)
         WriteLog("[WARNING]", message);
   }
   
   // Error log
   void Error(string message)
   {
      if(log_level <= LOG_ERROR)
         WriteLog("[ERROR]", message);
   }
   
   // Critical log
   void Critical(string message)
   {
      if(log_level <= LOG_CRITICAL)
         WriteLog("[CRITICAL]", message);
   }
   
   // ========================================================================
   // YARDIMCI FONKSİYONLAR
   // ========================================================================
   
   // Zamanı al (HH:MM:SS)
   string GetTime()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      return StringFormat("%02d:%02d:%02d", 
                         dt.hour, dt.min, dt.sec);
   }
   
   // Tarihi al (YYYY-MM-DD)
   string GetDate()
   {
      MqlDateTime dt;
      TimeToStruct(TimeCurrent(), dt);
      
      return StringFormat("%04d-%02d-%02d", 
                         dt.year, dt.mon, dt.mday);
   }
   
   // ========================================================================
   // PRIVATE FONKSİYONLAR
   // ========================================================================
   
private:
   void WriteLog(string level, string message)
   {
      string formatted_message = StringFormat("[%s %s] %s - %s", 
                                             GetDate(),
                                             GetTime(),
                                             level,
                                             message);
      
      // Console'ye yazdır
      if(console_logging)
         Print(formatted_message);
      
      // Dosyaya yaz
      if(file_logging && log_file_handle != INVALID_HANDLE)
      {
         FileWrite(log_file_handle, formatted_message);
         FileFlush(log_file_handle);  // Buffer'ı boşalt
      }
   }
};

// ============================================================================
// GLOBAL LOGGER INSTANCE
// ============================================================================

CLogger g_Logger;

#endif // __LOGGER_MQH__