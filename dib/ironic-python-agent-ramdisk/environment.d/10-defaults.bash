export IPA_REMOVE_FIRMWARE=${IPA_REMOVE_FIRMWARE:-amdgpu,netronome,qcom,ti-communication,ti-keystone,ueagle-atm,rsi,mrvl,brcm,mediatek,ath10k,rtlwifi,rtw88,rtw89,libertas,ath11k,mellanox/mlxsw_spectrum}

# NOTE(TheJulia): List of what each item represents for future context
# amdgpu == AMD/ATI Radeon/Vega/Raven firmware for drivers
# netronome == Netronome Agilio Smartnics
# qcom = Qualcom SoC firmware
# ti-communication == Texas Instruments SoC firmware
# ti-keystone == Texas Instruments baseband firmware
# ueagle-atm == ADSL/ATM interface card firmware
# rsi == Redpine wifi chip firmware
# mrvl == Marvell wifi chip and prestera ethernet switch ASIC firmware
# brcm == Broadcom wifi firmware
# mediatek == Mediatek wifi and SoC (think chromebook) firmware
# ath10k == Qualcom Atheros 10k firmware
# rtlwifi == Realtek Wifi firmware
# rtw88 == Realtek wireless
# rtw89 == Realtek wireless
# libertas == Marvell libertas wifi
# auth11k == Qualcomm atheros WLAN
# mellanox/mlxsw_spectrum = Mellanox Spectrum Switch ASIC
