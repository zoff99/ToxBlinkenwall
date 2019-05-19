#!/usr/bin/expect -f

set mac [lindex $argv 0]

set prompt "#"
spawn bluetoothctl

expect -re $prompt
send "connect $mac\r"
sleep 3
expect {
	-re "Failed to connect: org.bluez.Error.Failed" {
                send_user "Another Device is already connected, disconnect first\n"
                send "quit\r"
                expect eof
                exit -1
        }

	-re "Device $mac not available" {
		expect -re $prompt
		send_user "Devices does not exist\n"
		send "quit\r"
		expect eof
		exit -1
	}
	-re "Device $mac Connected: yes" {
		expect -re $prompt
		send_user "Succesfully connected\n"
		expect -re $prompt
		send "quit\r"
                expect eof
                exit 1
	}

	-re "Connection successful" {
                expect -re $prompt
                send_user "Already connected with the same devices, no errors, just continuing\n"
		expect -re $prompt
		send "quit\r"
                expect eof
                exit 1
	}
}


