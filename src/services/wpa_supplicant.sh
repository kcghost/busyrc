
try_wpa_supplicant() {
	echo_color 3 "waiting for interface ${1}..."
	wait_on "netif_exists ${1}"
	echo_color 3 "interface ${1} is available, starting wpa_supplicant for it"
	wpa_supplicant -Dwext -B -s -i"${1}" -c/etc/wpa_supplicant.conf
}

wpa_supplicant_start() {
	for netif in ${WIFI_INTERFACES}; do
		try_wpa_supplicant "${netif}" &
	done
}
