#ifndef _PPIDE_H_ 
#define _PPIDE_H_  

#include <stdint.h>  

#ifdef __cplusplus
extern "C" {     
#endif
    void WRDY(void);
    void SELPIO8(void);
    void SELMST(void);
    void IDERST(void);

    void DELAYN(uint16_t delayms);

    void IDE_INIT(void);     
    uint16_t IDE_GET_ERROR(void);     
    uint32_t IDE_GET_LBA(void);     
    void IDE_SET_LBA(uint32_t lba); // Added parameter name     
    uint8_t IDE_GET_DISK_INFO(uint8_t *buffer);     
    uint8_t IDE_READ_SECTOR(uint8_t *buffer);     
    uint8_t IDE_WRITE_SECTOR(uint8_t *buffer);     
    uint8_t IDE_DETECT(void); 

#ifdef __cplusplus
}  
#endif

#endif /* _PPIDE_H_ */
