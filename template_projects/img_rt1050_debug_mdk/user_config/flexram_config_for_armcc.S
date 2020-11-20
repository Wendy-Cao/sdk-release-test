                PRESERVE8
                THUMB

REG_IOMUXC_GPR14                    EQU     0x400AC038
REG_IOMUXC_GPR16                    EQU     0x400AC040
REG_IOMUXC_GPR17                    EQU     0x400AC044
BIT_GPR16_ITCM_EN                   EQU     (1<<0)
BIT_GPR16_DTCM_EN                   EQU     (1<<1)
BIT_GPR16_FLEX_RAM_BANK_CFG_SEL     EQU     (1<<2)
MASK_GPR14_DTCM_SZ                  EQU     (0xF << 20)
MASK_GPR14_ITCM_SZ                  EQU     (0xF << 16)


                AREA  |.text.flex_ram_config|, CODE, READONLY
                EXPORT  flex_ram_config

;�˺��������ṩ��һ�����Խ�FlexRAMȫ������ΪDTCM��ITCM����OCRAM�Ļ���,
;��ֻ���ڴ���������SDRAM����Flexspi Flash��ʱ�Żᱻ���á�

flex_ram_config     PROC
; ���Ƚ�DTCM��ITCM��ͣ��
                ldr     r0, = REG_IOMUXC_GPR16;
                ldr     r1,[r0];
                bic     r1,#BIT_GPR16_ITCM_EN
                bic     r1,#BIT_GPR16_DTCM_EN;
                str     r1,[r0];
                dsb

; ѡ��fuse������FlexRam
                ldr     r0, = REG_IOMUXC_GPR16;
                ldr     r1,[r0];
                bic     r1,#BIT_GPR16_FLEX_RAM_BANK_CFG_SEL
                str     r1,[r0];
                dsb


; ����GPR17�е�FLEX RAM,ȫ��ΪDTCM
                ldr     r1, = 0xAAAAAAAA;
                ldr     r0, = REG_IOMUXC_GPR17;
                str     r1,[r0];
                dsb
                isb

; ʹ�����üĴ���������FLEXRAM
                ldr     r0, = REG_IOMUXC_GPR16;
                ldr     r1,[r0];
                orr     r1,#BIT_GPR16_FLEX_RAM_BANK_CFG_SEL
                str     r1,[r0];
                dsb
                isb

; ����IOMUXC_GPR_GPR14�Ĵ�����ITCM��СΪ0, DTCM��СΪ512KB
                ldr     r0, = REG_IOMUXC_GPR14;
                ldr     r1, [r0]
                bic     r1,#MASK_GPR14_ITCM_SZ

                bic     r1,#MASK_GPR14_DTCM_SZ
                orr     r1,#(0xA << 20);
                str     r1,[r0];
                dsb

; GPR16 ��ʹ��DTCM
                ldr     r0, = REG_IOMUXC_GPR16;
                ldr     r1,[r0];
                orr     r1,#BIT_GPR16_DTCM_EN;
                str     r1,[r0];
                dsb
                isb
                bx  lr
                ENDP

; �˺�����������ʱ����pll2_pfd2��ʱ�ӣ�����SEMC��������SDRAM���г�ʼ��
                AREA    |.text.init_sdram_no_context_save|, CODE, READONLY, ALIGN=3
                EXPORT  init_sdram_no_context_save
                EXPORT  init_sdram_no_context_save_End
                EXPORT  init_sdram_no_context_save_Size

init_sdram_no_context_save  PROC

                ; ��ʼ��PLL2_SYSΪ528M
                ldr         r1,=0x400d8030;
                ldr         r0,[r1]
                orr         r0,#1<<16          ; bypass
                str         r0,[r1];
                orr         r0,#1<<12          ; power down
                str         r0,[r1]
               
wait_for_unlock1
                ldr         r0,[r1];            
                tst         r0,#1<<31
                bne         wait_for_unlock1

                
                orr         r0,#1<<0            ; div select
                str         r0,[r1];
               
                bic         r0,#1<<12           ; power up
                str         r0,[r1];
wait_for_unlock2
                ldr         r0,[r1]             
                tst         r0,#1<<31
                beq         wait_for_unlock2

                
                orr         r0,#1<<13           ; enable output
                str         r0,[r1];
                
                bic         r0,#1<<16           ; un bypass
                str         r0,[r1];

                ; PLL2_PFD2 = 396M
                ldr         r1,=0x400D8100;
                ldr         r0,[r1]
                bic         r0,#0xFF<<16
                orr         r0,#0x18<<16
                str         r0,[r1];

                ; SEMC_ALT_SEL = PLL2_PFD2
                ; SEMC_CLK_SEL = SEMC_ALT_SEL
                ldr         r1,=0x400FC014
                ldr         r0,[r1]
                bic         r0,#1<<7
                orr         r0,#1<<6
                str         r0,[r1]

                ; SEMC CLK PODF = 3
                ; SEMC_CLK_ROOT = 132M
                bic         r0,#0x7<<16
                orr         r0,#0x2<<16
                str         r0,[r1];

                ; �ȴ�handshake
                ldr         r1, = 0x400fc048
wait_for_handshake
                ldr         r0,[r1]
                cmp         r0,#0
                bne         wait_for_handshake

                ; ��ʼ��sdram
                mov     r0,#0
                ldr     r1, = 0x401F8014
                ldr     r2, = 0x401F80BC

config_sdram_iomux
                str     r0, [r1], #4
                cmp     r1, r2
                bcc     config_sdram_iomux

                ; pad ctrl
                mov     r0,#0x000000F1
                ldr     r1, = 0x401F8204
                ldr     r2, = 0x401F82AC
config_sdram_padctrl
                str     r0, [r1], #4
                cmp     r1, r2
                bcc     config_sdram_padctrl

                ; config semc
                ldr     r0, = 0x1f000000
                ldr     r1, = 0x402F0000
                str     r0, [r1], #4

                ldr     r0, = 0x00000008
                str     r0, [r1], #4

                ldr     r0, = 0x00030524
                str     r0, [r1], #4

                ldr     r0, = 0x06030524
                str     r0, [r1], #4

                ldr     r0, = 0x8000001B
                str     r0, [r1], #4

                ldr     r0, = 0x90000021
                str     r0, [r1]

                ldr     r0, = 0x00000F27
                ldr     r1, = 0x402F0040
                str     r0, [r1], #4

                ldr     r0, = 0x00661922
                str     r0, [r1], #4

                ldr     r0, = 0xFF090920
                str     r0, [r1], #4

                ldr     r0, = 0x28200A06
                str     r0, [r1]

                ldr     r0, = 0x00000002
                ldr     r1, = 0x402F0094
                str     r0, [r1], #4

                ldr     r0, = 0x00000000
                str     r0, [r1]
                dsb

                ; auto refresh
                ldr     r3,=0x402f003c     ; clear status
                ldr     r2,=0x3F
                str     r2,[r3]

                ldr     r0, = 0x80000000
                ldr     r1, = 0x402F0090
                str     r0, [r1]

                ldr     r0, = 0xA55A000F
                ldr     r1, = 0x402F009C
                str     r0, [r1]
wait_ip_command_done1
                ldr     r2,[r3]            
                tst     r2,#0x3
                beq     wait_ip_command_done1

                ; auto refresh
                ldr     r3,=0x402f003c      ; clear status
                ldr     r2,=0x3F
                str     r2,[r3]

                ldr     r0, = 0x80000000
                ldr     r1, = 0x402F0090
                str     r0, [r1]

                ldr     r0, = 0xA55A000F
                ldr     r1, = 0x402F009C
                str     r0, [r1]
wait_ip_command_done2
                ldr     r2,[r3]            
                tst     r2,#0x3
                beq     wait_ip_command_done2


                ; config sdram mode
                ldr     r3,=0x402f003c        ; clear status
                ldr     r2,=0x3F
                str     r2,[r3]

                ldr     r0, = 0x00000032
                ldr     r1, = 0x402F00A0
                str     r0, [r1]

                ldr     r0, = 0x80000000
                ldr     r1, = 0x402F0090
                str     r0, [r1]

                ldr     r0, = 0xA55A000A
                ldr     r1, = 0x402F009C
                str     r0, [r1]
                nop

wait_ip_command_done3
                ldr     r2,[r3]             ;wait for ip command done
                tst     r2,#0x3
                beq     wait_ip_command_done3
                ldr     r2,=0x3F            ;clear status
                str     r2,[r3]

                ldr     r0, = 0x28200A07
                ldr     r1, = 0x402F004C
                str     r0, [r1]
                dsb

                bx      lr
                nop
                ENDP

init_sdram_no_context_save_End               

init_sdram_no_context_save_Size  EQU     init_sdram_no_context_save_End - init_sdram_no_context_save

                END