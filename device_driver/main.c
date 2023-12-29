#include <stdio.h>
#include <stdint.h>
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
	  int delay= 0, iteration=0;
	  unsigned int text[AES_WORDS_OPS], key[AES_WORDS_OPS], crypto[AES_WORDS_OPS];
	  XTime start_AES_time, stop_AES_time;

	  print_AES_Accelerator_ID();
	  print_status_register();
	  printf("Clock Frequency: %d Hz\n\r", XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ);

	  key[0] = 0x2B7E1516;
	  key[1] = 0x28AED2A6;
	  key[2] = 0xABF71588;
	  key[3] = 0x09CF4F3C;
	  printf("Setting AES 128-bit key: %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
	  set_key_128Bits(key);

	  text[0] = 0x3243F6A8;
	  text[1] = 0x885A308D;
	  text[2] = 0x313198A2;
	  text[3] = 0xE0370734;
	  printf("Setting plain text 128-bit to be encrypted: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
	  set_plain_text(text);

	  printf("Start AES accelerator's key expansion\n\r");
	  XTime_GetTime(&start_AES_time);
	  start_key_expansion();
	  while(! (*(aes_accelerator_baseaddr_p+3)))		// Better to use interrupts
	  {
	  }
	  XTime_GetTime(&stop_AES_time);
	  printf("Key expansion status : 0x%08x\n\r", get_key_expansion_status());
	  printf("AES Accelerator's key expansion time laps: %f us\n\r", (float)(stop_AES_time - start_AES_time)/(float)XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ*1000000.0f);

	  printf("Start AES accelerator's Encryption\n\r");
	  XTime_GetTime(&start_AES_time);
	  start_encryption();
	  while(!(*(aes_accelerator_baseaddr_p+2)))		// Better to use interrupts
	  {
	  }
	  XTime_GetTime(&stop_AES_time);
	  printf("Encryption status : 0x%08x \n\r", get_encryption_status());
	  printf("AES Accelerator's Encryption time laps: %f us\n\r", (float)(stop_AES_time - start_AES_time)/(float)XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ*1000000.0f);

	  get_encrypted_text(crypto);
	  printf("AES 128-bit key : %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
	  printf("Plain text 128-bit: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
	  printf("Encrypted cipher AES 128-bit: %08x%08x%08x%08x\n\r", crypto[0], crypto[1], crypto[2], crypto[3]);
	  printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));

	  printf("Stop AES accelerator's Encryption\n\r");
	  stop_encryption();
	  for (delay=0; delay<999999999; delay++);

	  while(1)
	  {
		  printf("**************** Print %d iteration of key to check stability ****************\n\r", ++iteration);
		  printf("Start AES accelerator's Encryption\n\r");
		  XTime_GetTime(&start_AES_time);
		  start_encryption();
		  while(!(*(aes_accelerator_baseaddr_p+2))){		// Better to use interrupts
		  }
		  XTime_GetTime(&stop_AES_time);

		  printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));
		  printf("Crypto status : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+2));
		  printf("Key status : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+3));
		  printf("AES 128-bit key : %08x%08x%08x%08x\n\r", key[0], key[1], key[2], key[3]);
		  printf("Plain text 128-bit: %08x%08x%08x%08x\n\r", text[0], text[1], text[2], text[3]);
		  printf("Encrypted cipher AES 128-bit: %08x%08x%08x%08x\n\r", *(aes_accelerator_baseaddr_p+12), *(aes_accelerator_baseaddr_p+13), *(aes_accelerator_baseaddr_p+14), *(aes_accelerator_baseaddr_p+15));
		  printf("AES Accelerator's Encryption time laps: %f us\n\r", (float)(stop_AES_time - start_AES_time)/(float)XPAR_CPU_CORTEXA9_CORE_CLOCK_FREQ_HZ*1000000.0f);
		  printf("Stop AES accelerator's Encryption\n\r");
		  stop_encryption();
		  for (delay=0; delay<99999999; delay++);
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
	printf("status registers : 0x%08x \n\r", *(aes_accelerator_baseaddr_p+17));
}

unsigned int get_key_expansion_status(){
	return *(aes_accelerator_baseaddr_p+3);
}

unsigned int get_encryption_status(){
	return *(aes_accelerator_baseaddr_p+2);
}
void print_AES_Accelerator_ID(){
	printf("AES Accelerator ID: 0x%08x \n\r", *(aes_accelerator_baseaddr_p+16));
}
void get_encrypted_text(unsigned int crypto[AES_WORDS_OPS]){
	crypto[0]=*(aes_accelerator_baseaddr_p+12);
	crypto[1]=*(aes_accelerator_baseaddr_p+13);
	crypto[2]=*(aes_accelerator_baseaddr_p+14);
	crypto[3]=*(aes_accelerator_baseaddr_p+15);

}
