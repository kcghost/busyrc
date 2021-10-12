
wpa_supplicant_start() {
	wait_on "iwconfig ${WIFI_INTERFACE}"
	wpa_supplicant -Dwext -B -i"${WIFI_INTERFACE}" -c/etc/wpa_supplicant.conf
}
