#include "xparameters.h"
#include "xgpio.h"
#include "xgpiops.h"
#include "xtime_l.h"

volatile unsigned int *aes_accelerator_baseaddr_p = (volatile unsigned int *)XPAR_AES_128BIT_ACCELERAT_0_S_AXI_BASEADDR;
const unsigned int AES_BLOCK_SIZE=16;
const unsigned int AES_WORDS_OPS=4;
//====================================================

void print_AES_Accelerator_ID();
void print_status_register();
void set_plain_text(unsigned int text[AES_WORDS_OPS]);
void set_key_128Bits(unsigned int key[AES_WORDS_OPS]);
void start_key_expansion();
void start_encryption();
void stop_encryption();
unsigned int get_key_expansion_status();
unsigned int get_encryption_status();
void get_encrypted_text(unsigned int crypto[AES_WORDS_OPS]);

int main (void)
{
	  int i= 0, j=0;
	  unsigned int text[AES_WORDS_OPS];
	  unsigned int key[AES_WORDS_OPS];
	  unsigned int crypto[AES_WORDS_OPS];
	  XTime start_XTime, stop_time;

	  print_AES_Accelerator_ID();
	  print_status_register();
	  xil_printf("Clock Frequency: %d Hz\n\r", XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ);

	  key[0] = 0x2B7E1516;
	  key[1] = 0x28AED2A6;
	  key[2] = 0xABF71588;
	  key[3] = 0x09CF4F3C;
	  xil_printf("Setting AES 128-bit key: %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
	  set_key_128Bits(key);

	  text[0] = 0x3243F6A8;
	  text[1] = 0x885A308D;
	  text[2] = 0x313198A2;
	  text[3] = 0xE0370734;
	  xil_printf("Setting plain text 128-bit to be encrypted: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
	  set_plain_text(text);

	  xil_printf("Start AES accelerator's key expansion\n\r");
	  XTime_GetTime(&start_XTime);
	  start_key_expansion();

	  while(! (*(aes_accelerator_baseaddr_p+3)))
	  {
	  }
	  XTime_GetTime(&stop_time);
	  xil_printf("Key expansion status : 0x%08x\n\r", get_key_expansion_status());
	  //xil_printf("AES Accelerator's key expansion time laps: %f ms\n\r", (float)(stop_time - start_XTime)/(float)XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ * (float)1000);

	  xil_printf("Start AES accelerator's Encryption\n\r");
	  XTime_GetTime(&start_XTime);
	  start_encryption();

	  while(!(*(aes_accelerator_baseaddr_p+2)))
	  {
	  }
	  XTime_GetTime(&stop_time);
	  xil_printf("Encryption status : 0x%08x \n\r", get_encryption_status());
	  //xil_printf("AES Accelerator's Encryption time laps: %f ms\n\r", (float)(stop_time - start_XTime)/(float)XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ * (float)1000);

	  get_encrypted_text(crypto);
	  xil_printf("AES 128-bit key : %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
	  xil_printf("Plain text 128-bit: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
	  xil_printf("Encrypted cipher AES 128-bit: %08x%08x%08x%08x\n\r", crypto[0], crypto[1], crypto[2], crypto[3]);
	  xil_printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));

	  xil_printf("Stop AES accelerator's Encryption\n\r");
	  stop_encryption();
	  for (i=0; i<999999999; i++);

	  while(1)
	  {
		  xil_printf("**************** Print next iteration of key to check stability ****************\n\r");
		  xil_printf("Start AES accelerator's Encryption\n\r");
		  start_encryption();

		  while(!(*(aes_accelerator_baseaddr_p+2))){
		  }

		  xil_printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));
		  xil_printf("Crypto status : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+2));
		  xil_printf("Key status : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+3));
		  xil_printf("AES 128-bit key : %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
		  xil_printf("Plain text 128-bit: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
		  xil_printf("Encrypted cipher AES 128-bit: %08x%08x%08x%08x\n\r", *(aes_accelerator_baseaddr_p+12), *(aes_accelerator_baseaddr_p+13), *(aes_accelerator_baseaddr_p+14), *(aes_accelerator_baseaddr_p+15));
		  xil_printf("Stop AES accelerator's Encryption\n\r");
		  stop_encryption();
		  for (i=0; i<99999999; i++);
	  }

	  return 0;
}

void set_plain_text(unsigned int text[AES_WORDS_OPS]){
	  *(aes_accelerator_baseaddr_p+8) = *(text++);
	  *(aes_accelerator_baseaddr_p+9) = *(text++);
	  *(aes_accelerator_baseaddr_p+10) = *(text++);
	  *(aes_accelerator_baseaddr_p+11) = *(text);
}
void set_key_128Bits(unsigned int key[AES_WORDS_OPS]){
	  *(aes_accelerator_baseaddr_p+4) = *(key++);
	  *(aes_accelerator_baseaddr_p+5) = *(key++);
	  *(aes_accelerator_baseaddr_p+6) = *(key++);
	  *(aes_accelerator_baseaddr_p+7) = *(key++);
}
void start_key_expansion(){
	*(aes_accelerator_baseaddr_p+0) = 0x00000001;
}
void start_encryption(){
	*(aes_accelerator_baseaddr_p+1) = 0x00000001;
}
void stop_encryption(){
	*(aes_accelerator_baseaddr_p+1) = 0x00000000;
}

void print_status_register(){
	xil_printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));
}

unsigned int get_key_expansion_status(){
	return *(aes_accelerator_baseaddr_p+3);
}

unsigned int get_encryption_status(){
	return *(aes_accelerator_baseaddr_p+2);
}
void print_AES_Accelerator_ID(){
	xil_printf("AES Accelerator ID: 0x%08x \n\r", *(aes_accelerator_baseaddr_p+16));
}
void get_encrypted_text(unsigned int crypto[AES_WORDS_OPS]){
	crypto[0]=*(aes_accelerator_baseaddr_p+12);
	crypto[1]=*(aes_accelerator_baseaddr_p+13);
	crypto[2]=*(aes_accelerator_baseaddr_p+14);
	crypto[3]=*(aes_accelerator_baseaddr_p+15);

}
