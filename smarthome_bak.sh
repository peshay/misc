#!/bin/bash
# gdrive backup
## Backup Smarthome stuff to Google Drive

gdrive_sync_up() {
	src=$1
	dst=$2
	gdrive sync upload $src $dst
}

backup_homebdridge() {
	homebridge=1XT0Q1P01b0xJT5mBI7mdSTEvGmdqrFPw
	gdrive_sync_up /home/homebridge/.homebridge/ $homebridge
}

backup_influxdb() {
	influxdb=1l_OjhG0grrf9tqp5GOVLC4172noNdCQ4
	influxd backup /tmp/mysnapshot
	gdrive_sync_up /tmp/mysnapshot/ $influxdb
	rm -rf /tmp/mysnapshot
}

backup_zway() {
	zway=1UQDCqIyW9Hjhx5HJenW-G70tTML_iY-n
}

backup_grafana() {
	grafana=15hCA9wmbp0kLduMn2b6VRLSgmzRgBL0m
}

backup_unifi() {
	unifi=13dFDqfaTPhwcsHKob-tq0nvG2mC2HhSr
}

backup_homebdridge
backup_influxdb
