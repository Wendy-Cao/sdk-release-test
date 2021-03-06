/*******************************************************************************
*                                 AWorks
*                       ---------------------------
*                       innovating embedded platform
*
* Copyright (c) 2001-2020 Guangzhou ZHIYUAN Electronics Co., Ltd.
* All rights reserved.
*
* Contact information:
* web site:    http://www.zlg.cn/
*******************************************************************************/

/**
 * \file
 * \brief AWBus-lite iMX1050 GPT2 CAP 配置文件
 *
 * \internal
 * \par modification history
 * - 1.00 2020-09-09  licl, first implementation
 * \endinternal
 */

#ifndef  __AWBL_HWCONF_IMX1050_GPT2_CAP_H
#define  __AWBL_HWCONF_IMX1050_GPT2_CAP_H

#ifdef AW_DEV_IMX1050_GPT2_CAP

#include "aw_int.h"
#include "driver/cap/awbl_imx10xx_gpt_cap.h"

/* GPT2 Capture 通道与引脚信息 */
aw_local aw_const awbl_imx10xx_gpt_cap_devcfg_t __g_imx1050_gpt2_cap_devcfg_list[] = {

    /* CAP ID, 通道号, GPIO, CAP引脚功能 */
    {
        GPT2_CAP0,
        GPT_CAP_Channel_0,
        GPIO3_27,
        GPIO3_27_GPT2_CAPTURE1,
    },

    {
        GPT2_CAP1,
        GPT_CAP_Channel_1,
        GPIO3_26,
        GPIO3_26_GPT2_CAPTURE2,
    },
};

/** \brief GPT2 平台初始化函数 */
aw_local void __imx1050_gpt2_cap_plfm_init (void)
{
    int cap_gpios[AW_NELEMENTS(__g_imx1050_gpt2_cap_devcfg_list)];
    int i;

    for (i = 0; i < AW_NELEMENTS(__g_imx1050_gpt2_cap_devcfg_list); i++) {
        cap_gpios[i] = __g_imx1050_gpt2_cap_devcfg_list[i].gpio;
    }

    /* 引脚申请与配置 */
    if (aw_gpio_pin_request("gpt2_cap_gpios",
                             cap_gpios,
                             AW_NELEMENTS(cap_gpios)) == AW_OK) {

        for (i = 0; i < AW_NELEMENTS(__g_imx1050_gpt2_cap_devcfg_list); i++) {
            aw_gpio_pin_cfg(cap_gpios[i],
                            __g_imx1050_gpt2_cap_devcfg_list[i].func);
        }
    }
}

/** \brief GPT2 设备信息 */
aw_local aw_const awbl_imx10xx_gpt_cap_devinfo_t __g_imx1050_gpt2_cap_devinfo = {
    IMX1050_GPT2_BASE,                              /* 寄存器基地址 */
    IMX1050_CLK_CG_GPT2_SERIAL,                     /* 时钟 ID */
    INUM_GPT2,                                      /* 中断号 */
    &__g_imx1050_gpt2_cap_devcfg_list[0],           /* CAP配置信息 */
    AW_NELEMENTS(__g_imx1050_gpt2_cap_devcfg_list), /* 使用的CAP通道数 */
    {
            GPT2_CAP0,                              /**< \brief 最小ID编号 */
            GPT2_CAP1,                              /**< \brief 最大ID编号 */
    },
    __imx1050_gpt2_cap_plfm_init                    /* 平台初始化函数 */
};

/** \brief 设备实例内存静态分配 */
aw_local struct awbl_imx10xx_gpt_cap_dev __g_imx1050_gpt2_cap_dev;

#define AWBL_HWCONF_IMX1050_GPT2_CAP    \
    {                                   \
        AWBL_IMX10XX_GPT_CAP_NAME,      \
        0,                              \
        AWBL_BUSID_PLB,                 \
        0,                              \
        (struct awbl_dev *)&(__g_imx1050_gpt2_cap_dev), \
        &__g_imx1050_gpt2_cap_devinfo   \
    },

#else
#define AWBL_HWCONF_IMX1050_GPT2_CAP

#endif  /* AW_DEV_IMX1050_GPT2_CAP */

#endif  /* __AWBL_HWCONF_IMX1050_GPT2_CAP_H */

/* end of file */
