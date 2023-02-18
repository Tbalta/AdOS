#ifndef LOG_H
#define LOG_H


#define STR_HELPER(x) #x
#define STR(x) STR_HELPER(x)

#define LOG(fmt, ...)                                                      \
  {                                                                        \
    printf("\033[0;34m[INFO ]\033[0m(" __FILE__                            \
           ":" STR(__LINE__) "): " fmt "\r\n" __VA_OPT__(, ) __VA_ARGS__); \
  }

#define WAIT                     \
  {                              \
    for (int i = 0; i < 50; i++) \
      send_string(COM1, " ");    \
  }

#define DEBUG()                           \
  {                                       \
    LOG("Breakpoint reached");            \
    char __FILE__buffer[1];               \
    serial_read(COM2, __FILE__buffer, 1); \
  }

#define LOG_PANIC(fmt, ...) \
  while (1)             \
  LOG(fmt, __VA_ARGS__)
#endif