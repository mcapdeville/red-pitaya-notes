#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <time.h>

#define WRITE_ADDR	0x40000000
#define CONTROL_OFFSET	11
#define READ_ADDR	0x40001000
#define RESULT_OFFSET	0
#define STATUS_OFFSET	1

#define CONTROL_STOP	1
#define STATUS_RUNNING	1
#define STATUS_FOUND	2

const uint32_t Test[11] = {
// State
	0xf1cb2516,0xa66bbca5,0x8421d148,0x009e3841,
	0x7679dca9,0xf2c62f8a,0xcf709cb7,0xd0eb6f57,
// Data
	0x49fa0a4c,0xd837e84d,0x2194261a,
};
const uint32_t TestResult = 0x02b3c27b;

volatile uint32_t * WriteReg;
volatile uint32_t * ReadReg;
volatile uint32_t * Control;
volatile uint32_t * Result;
volatile uint32_t * Status;
int fd;

struct timespec ts1,ts2;
float hashrate;

int main(int argc,char** argv) {
	int i;
	int32_t Stat;

	if((fd = open("/dev/mem", O_RDWR)) < 0)
	{ 
		perror("open");
		return -1;
	}

	WriteReg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd, WRITE_ADDR);
	ReadReg	 = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, fd, READ_ADDR);
	Control = (uint32_t*)(WriteReg+CONTROL_OFFSET);
	Result = (uint32_t*)(ReadReg+RESULT_OFFSET);
	Status = (uint32_t*)(ReadReg+STATUS_OFFSET);


	if ((*Status & STATUS_RUNNING) && (*Result<TestResult) && (argc<2 || strcmp(argv[1],"-r"))) {
		printf("Miner is allready running : Result =%X : Status = %X\n",*Result,*Status);
		exit(1);
	}

	*Control = CONTROL_STOP; 
	printf("Miner stoped : Result =%X : Status = %X\n",*Result,*Status);
	for (i=0;i<11;i++)
		WriteReg[i]=Test[i];
	*Control = 0;
	clock_gettime(CLOCK_MONOTONIC,&ts1);
	printf("Miner started : Result =%X : Status = %X\n",*Result,*Status);

	while (*Status & STATUS_RUNNING) {
	}
	clock_gettime(CLOCK_MONOTONIC,&ts2);

	hashrate = ((float)(*Result))/(((float)(ts2.tv_sec-ts1.tv_sec))*1000000.0+((float)(ts2.tv_nsec-ts1.tv_nsec))/1000.0);
	printf("\nMiner finish : Result =%X : Status = %X ",*Result,(*Status&3));

	if (*Status & STATUS_FOUND) {
		printf("Found : Result = %X waiting for %X",*Result,TestResult);
		if (*Result==TestResult)
			printf(" => Miner is working !\n");
		else
			printf(" => Miner is not working !\n");
	}
	else
		printf("Not Found : Result = %X\n",*Result);

	printf("Hashrate : %f\n",hashrate);

		
	close(fd);

	return 0;
}
