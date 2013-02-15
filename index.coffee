bootstrapper = require 'bootstrapper'
ENV = bootstrapper.ENV

{partial} = require 'libprotein'

logger_proto = [
    ['info',    [], 'varargs']
    ['warn',    [], 'varargs']
    ['error',   [], 'varargs']
    ['debug',   [], 'varargs']
]

say = (a...) -> console?.log a...
read_env = (key) -> ENV?[key]
log = (flag, prefix, msg...) -> say (["[#{prefix}]"].concat msg)... if (read_env flag) is true

info =  partial log, 'LOG_INFO',  'INFO'
warn =  partial log, 'LOG_WARN',  'WARN'
error = partial log, 'LOG_ERROR', 'ERROR'
debug = partial log, 'LOG_DEBUG', 'DEBUG'

console_logger = (opts) -> {info, warn, error, debug}


module.exports =
    info: info
    warn: warn
    error: error
    debug: debug

    protocols:
        definitions:
            ILogger: logger_proto
        implementations:
            ILogger: console_logger