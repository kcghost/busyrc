
wpa_supplicant_start() {
	for WIFI_INTERFACE in ${WIFI_INTERFACES}; do
		wait_on "iwconfig ${WIFI_INTERFACE}"
		wpa_supplicant -Dwext -B -s -i"${WIFI_INTERFACE}" -c/etc/wpa_supplicant.conf
	done
}
