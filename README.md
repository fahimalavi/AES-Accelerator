# AES Hardware Accelerator 
## Description
This built from scratch AES hardware accelerator performs encryption and decryption of 128-bit data with 128-bit keys according to the advanced encryption standard (AES) (FIPS PUB 197) in hardware.
The AES accelerator features are:
* Encryption and decryption according to AES FIPS PUB 197 with 128-bit key
* On-the-fly key expansion
## AES Accelerator Operation
The AES accelerator is configured with user software. This section describe the setup and operation. Internally, the AES algorithm’s operations are performed on a two-dimensional array of bytes called the
State. For AES-128, the State consists of four rows of bytes, each containing four bytes.
The steps to perform encryption are:
* Set AES_RESET_REGISTER to 0 (Ensure crypto accelerator is off)
* Set AES-128 bit key in AES_KEY_REGISTER (as shown in device driver) 
* Set AES_RESET_REGISTER to 1
* Set AES_START_KEY_EXPANSION_REGISTER to 1
* Check if AES_KEY_STATUS_REGISTER is 1 when key expansion is completed
* Set 128 bit plain text in AES_PLAIN_TEXT_REGISTER
* Set AES_ENCRYPT_ENABLE_REGISTER to 1
* Check if AES_ENCRYPTION_STATUS is 1 when encryption is completed
![Embedded_software_logs](https://github.com/fahimalavi/AES-Accelerator/blob/main/images/AES_128bit_Encryption_output.jpg?raw=true)
## System on Chip
I have used Digilent Zybo build to make complete system on chip for this AES accelerator. This architecture tightly integrates a dual-core ARM Cortex-A9 processor with Xilinx 7-series Field Programmable Gate Array (FPGA) logic.
![AES ACCELERATOR SOC DIAGRAM](https://github.com/fahimalavi/AES-Accelerator/blob/main/images/AES_ACCELERATOR_SOC_DIAGRAM.jpg?raw=true)

## Test bench
* Test Bench AES key expansion
![Test Bench](https://github.com/fahimalavi/AES-Accelerator/blob/main/images/key_expansion.jpg?raw=true)

* Test Bench AES encryption
![Test Bench](https://github.com/fahimalavi/AES-Accelerator/blob/main/images/encryption_simulation.jpg?raw=true)

Contact me regarding additional features of RTL design for
- AES-256
- Test Benches

MIT licensed.

Fahim Alavi : Year 2023

