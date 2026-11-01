#include <stdint.h>

#define DSP_PITCH_CONFIG *((volatile uint32_t *)(0x20000000)) 
#define DSP_AUDIO_IN     *((volatile uint32_t *)(0x20000004)) 
#define I2S_STATUS       *((volatile uint32_t *)(0x20000010)) 
#define I2S_DATA_RX      *((volatile uint32_t *)(0x20000014)) 
#define BSRAM_Buffer      ((volatile uint32_t *)(0x40000000))
int main(void) {
    uint32_t frame_index = 0;    

    // Test thử 2 frame âm thanh 
    while (frame_index < 2) {
        // chờ I2S báo có dữ liệu (Polling)
        while ((I2S_STATUS & 0x01) == 0) {
            // chờ dữ liệu
        }
        uint32_t audio_sample = I2S_DATA_RX; // đọc dữ liệu âm thanh từ I2S
        BSRAM_Buffer[frame_index] = audio_sample; // lưu dữ liệu vào B
        uint32_t buffered_sample = BSRAM_Buffer[frame_index]; // đọc dữ liệu từ BSRAM_Buffer
        // Đẩy từ BSRAM_Buffer sang DSP
        DSP_AUDIO_IN = buffered_sample; // gửi dữ liệu âm thanh đến DSP
        frame_index++;
    }
    while (1) ;
    return 0;
}