{partial, or_, and_, bool, is_object, is_array} = require 'libprotein'

LOGCFG = try
    bt = require 'bootstrapper'
    if bt and (is_object bt.ENV) and (is_object bt.ENV.LOG)
        bt.ENV.LOG
    else
        null
catch e
    if process and (is_object process.ENV) and (is_object process.ENV.LOG)
        process.ENV.LOG
    else if window and (is_object window.ENV) and (is_object window.ENV.LOG)
        window.ENV.LOG
    else
        null

if window and LOGCFG
    window.logger_mute_ns_except = (exp) ->
        if exp and not is_array exp
            exp = [exp]

        for k of LOGCFG.ns
            LOGCFG.ns[k] = if k in exp then true else false

    window.logger_unmute_ns = ->
        for k of LOGCFG.ns
            LOGCFG.ns[k] = true

    window.logger_mute_ns = ->
        for k of LOGCFG.ns
            LOGCFG.ns[k] = false

    window.logger_unmute_level = ->
        for k of LOGCFG.level
            LOGCFG.ns[k] = true

    window.logger_mute_level = ->
        for k of LOGCFG.level
            LOGCFG.ns[k] = false

INFO = 'INFO'
WARN = 'WARN'
ERROR = 'ERROR'
DEBUG = 'DEBUG'
NOTICE = 'NOTICE'
LOG_LEVELS = [INFO, WARN, ERROR, DEBUG, NOTICE]

UNK_NS = UNK_NS

say = (log_level, log_ns, msgs) ->
    m = [(if log_level then "[#{log_level}]" else '[NOTICE]'),
         (if log_ns then "[#{log_ns}]" else "[#{UNK_NS}]")].concat msgs
    switch log_level
        when ERROR
            console?.error? m...
        when INFO
            console?.info m...
        when DEBUG
            console?.debug m...
        when WARN
            console?.warn m...
        else
            console?.log m...

log_level_enabled = (log_level) ->
    if LOGCFG then (LOGCFG.level?[log_level] is true) else true

log_ns_enabled = (log_ns) ->
    if LOGCFG then (LOGCFG.ns?[log_ns] is true) else true

log = (log_level, log_ns, msg...) ->
    if (and_ (log_level_enabled log_level),
             (log_ns_enabled log_ns))
        say log_level, log_ns, msg

get_namespaced_logger = (log_ns) ->
    if LOGCFG
        LOGCFG.ns or= {}
        unless LOGCFG.ns.hasOwnProperty log_ns
            LOGCFG.ns[log_ns] = true

    info:   partial log, INFO, log_ns
    warn:   partial log, WARN, log_ns
    error:  partial log, ERROR, log_ns
    debug:  partial log, DEBUG, log_ns
    notice: partial log, NOTICE, log_ns

module.exports =
    # for use like this: {info, warn,...} = require 'console.logger'
    info:   partial log, INFO, UNK_NS
    warn:   partial log, WARN, UNK_NS
    error:  partial log, ERROR, UNK_NS
    debug:  partial log, DEBUG, UNK_NS
    notice: partial log, NOTICE, UNK_NS

    # for use like this: {info, warn,...} = (require 'console.logger').ns 'my-ns'
    ns: get_namespaced_logger


    protocols:
        definitions:
            ILogger: [
                ['info',     [], {varargs: true}]
                ['warn',     [], {varargs: true}]
                ['error',    [], {varargs: true}]
                ['debug',    [], {varargs: true}]
                ['notice',   [], {varargs: true}]
            ]
        implementations:
            # for use like this: {info, warn,...} = dispatch_impl 'ILogger', 'my-ns'
            ILogger: get_namespaced_logger
