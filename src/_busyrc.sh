#compdef rc.d
_busyrc_commands(){
   local -a _cmds
   _cmds=(
      'start:start a service'
      'stop:stop a service'
      'restart:restart a running service'
      'list:list all services'
      )
   _describe 'command' _cmds
}
            
_arguments -C -A "-*" \
    '1:command:_busyrc_commands' \
    --help'[show basic usage]' \
    --version'[show version information]' \
