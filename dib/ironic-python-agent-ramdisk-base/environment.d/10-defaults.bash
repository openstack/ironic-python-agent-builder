# gdisk provides sgdisk, still used by old ironic-python-agent releases.
# Newer releases have removed the sgdisk usage, so this default can change
# to 0 in the future when ironic-python-agent-builder no longer needs to
# support building old ironic-python-agent releases
export DIB_IPA_HARDWARE_GDISK=${DIB_IPA_HARDWARE_GDISK:-1}

export IPA_REMOVE_FIRMWARE=${IPA_REMOVE_FIRMWARE:-amdgpu,netronome,qcom,ti-communication,ti-keystone,ueagle-atm,rsi,mrvl,brcm,mediatek,ath10k,rtlwifi,rtw88,rtw89,libertas,ath11k,mellanox/mlxsw_spectrum,s5p-mfc,ti/tas2781,ti-connectivity,TAS,ath3k,ath6k,ath9k,ath12k,rtl_bt,v4l,cirrus,dvb,mwl8k,mwlwifi,cypress,atmel,vicam,iwlwifi,intel/ibt,intel/dsp,nvidia,i915,xe,radeon,amdnpu,amlogic,LENOVO,intel/iwlwifi}

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
# ath11k == Qualcomm atheros WLAN
# mellanox/mlxsw_spectrum = Mellanox Spectrum Switch ASIC
# s5p-mfc = Samsung MFC SoC video codecs
# ti/tas2781 = Texas Instruments TAS2781 Notebook audio DSPs.
# ti-connectivity = Texas Instruments Wi-Fi/BT/FM/GPS
# TAS = Texas Instruments TAS2781 Notebook audio DSPs.
# ath3k = Qualcomm 802.11
# ath6k = Qualcomm 802.11
# ath9k = Qualcomm 802.11 PCI/PCI-E
# ath12k = Qualcomm Wi-Fi 7
# rtl_bt = Realtek Bluetooth
# v4l = General catch-all for Video 4 Linux, mainly Connexant hardware.
# cirrus = CirrusLogic DSP and Amplifier firmware
# dvb = General catch-all for digital tv adapter interfaces
# mwl8k == Marvell wireless
# mwlwifi == Marvell wireless
# cypress == Broadcom Wireless
# atmel == Atmel wireless
# vicam == Intel wireless
# iwlwifi == Intel wireless adapters (top-level /usr/lib/firmware/iwlwifi)
# intel/iwlwifi == Intel wireless adapters (under /usr/lib/firmware/intel/iwlwifi)
# intel/ibt == Intel bluetooth
# intel/dsp == Intel audio dsp
# nvidia == NVIDIA GPU firmware
# i915 == Intel integrated GPU firmware
# xe == Intel Xe GPU firmware
# radeon == AMD Radeon GPU firmware
# amdnpu == AMD NPU (AI accelerator) firmware
# amlogic == Amlogic ARM SoC firmware (consumer devices, not servers)
# LENOVO == Lenovo laptop-specific firmware
